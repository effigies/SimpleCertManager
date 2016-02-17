#!/bin/bash
# Simple Makefile-based certificate management system
#
# To create/update the Makefile for a site:
#
# ./update_site sub.domain.tld
#
# 2015 Chris Markiewicz

HOST=$1

mkdir -p $HOST

cat > $HOST/openssl.cnf <<END
[ req ]
distinguished_name = req_distinguished_name
prompt             = no
default_md         = sha256

[ req_distinguished_name ]
C            = US
ST           = None
L            = None
O            = $HOST
OU           = $HOST
CN           = $HOST
emailAddress = postmaster@$HOST
END

cat > $HOST/Makefile <<END
csr: $HOST.csr

key: $HOST.key

pem: $HOST.pem

pins: $HOST.key backup.key
	@echo -n "Current pin: "
	@openssl rsa -in $HOST.key -outform der -pubout 2>/dev/null |\\
		openssl dgst -sha256 -binary | base64
	@echo -n "Backup pin: "
	@openssl rsa -in backup.key -outform der -pubout 2>/dev/null |\\
		openssl dgst -sha256 -binary | base64

nginx-pins: $HOST.key backup.key
	@echo 'add_header Public-Key-Pins "max-age=15768000;pin-sha256=\"'\\
		\`openssl rsa -in $HOST.key -outform der -pubout 2>/dev/null |\\
			openssl dgst -sha256 -binary | base64\`'\";pin-sha256=\"'\\
		\`openssl rsa -in backup.key -outform der -pubout 2>/dev/null |\\
			openssl dgst -sha256 -binary | base64\`'\"";' | sed -e 's/" /"/g'

expire: $HOST.key backup.key
	mkdir expiring.\`date +%Y.%m.%d\`
	mv $HOST.key $HOST.pem $HOST.csr local.pem expiring.\`date +%Y.%m.%d\`
	mv backup.key $HOST.key

renew: expire csr

selfsign: $HOST.key
	openssl req -new -x509 -config openssl.cnf -key $HOST.key -out selfsigned.pem -days 1095

$HOST.key:
	openssl genpkey -algorithm RSA -out $HOST.key -pkeyopt rsa_keygen_bits:4096

backup.key:
	openssl genpkey -algorithm RSA -out backup.key -pkeyopt rsa_keygen_bits:4096

$HOST.csr: $HOST.key
	openssl req -new -key $HOST.key -config openssl.cnf -out $HOST.csr
	@cat $HOST.csr
	@echo "Save the resulting certificate as local.pem"

$HOST.pem: local.pem sca.server1.crt
	cat local.pem sca.server1.crt > $HOST.pem

sca.server1.crt:
	curl -O https://startssl.com/certs/sca.server1.crt
	dos2unix sca.server1.crt

ca.crt:
	curl -O https://startssl.com/certs/ca.crt
	dos2unix ca.crt

startssl.stapling.pem: ca.crt sca.server1.crt
	cat ca.crt sca.server1.crt > startssl.stapling.pem

prep: $HOST.key $HOST.pem startssl.stapling.pem

install: $HOST.key $HOST.pem startssl.stapling.pem
	cp $HOST.key /etc/ssl/private/
	cp $HOST.pem /etc/ssl/certs/
	cp startssl.stapling.pem /etc/ssl/certs/

installss: selfsigned.pem $HOST.key
	cp $HOST.key /etc/ssl/private/
	cp selfsigned.pem /etc/ssl/certs/$HOST.pem
END
