csr: sub.domain.tld.csr

key: sub.domain.tld.key

pem: sub.domain.tld.pem

pins: sub.domain.tld.key backup.key
	@echo -n "Current pin: "
	@openssl rsa -in sub.domain.tld.key -outform der -pubout 2>/dev/null |\
		openssl dgst -sha256 -binary | base64
	@echo -n "Backup pin: "
	@openssl rsa -in backup.key -outform der -pubout 2>/dev/null |\
		openssl dgst -sha256 -binary | base64

nginx-pins: sub.domain.tld.key backup.key
	@echo 'add_header Public-Key-Pins "max-age=15768000;pin-sha256=\"'\
		`openssl rsa -in sub.domain.tld.key -outform der -pubout 2>/dev/null |\
			openssl dgst -sha256 -binary | base64`'\";pin-sha256=\"'\
		`openssl rsa -in backup.key -outform der -pubout 2>/dev/null |\
			openssl dgst -sha256 -binary | base64`'\"";' | sed -e 's/" /"/g'

expire: sub.domain.tld.key backup.key
	mkdir expiring.`date +%Y.%m.%d`
	mv sub.domain.tld.key sub.domain.tld.pem sub.domain.tld.csr local.pem expiring.`date +%Y.%m.%d`
	mv backup.key sub.domain.tld.key

renew: expire csr

selfsign: sub.domain.tld.key
	openssl req -new -x509 -config openssl.cnf -key sub.domain.tld.key -out selfsigned.pem -days 1095

sub.domain.tld.key:
	openssl genpkey -algorithm RSA -out sub.domain.tld.key -pkeyopt rsa_keygen_bits:4096

backup.key:
	openssl genpkey -algorithm RSA -out backup.key -pkeyopt rsa_keygen_bits:4096

sub.domain.tld.csr: sub.domain.tld.key
	openssl req -new -key sub.domain.tld.key -config openssl.cnf -out sub.domain.tld.csr
	@cat sub.domain.tld.csr
	@echo "Save the resulting certificate as local.pem"

sub.domain.tld.pem: local.pem sca.server1.crt
	cat local.pem sca.server1.crt > sub.domain.tld.pem

sca.server1.crt:
	curl -O https://startssl.com/certs/sca.server1.crt
	dos2unix sca.server1.crt

ca.crt:
	curl -O https://startssl.com/certs/ca.crt
	dos2unix ca.crt

startssl.stapling.pem: ca.crt sca.server1.crt
	cat ca.crt sca.server1.crt > startssl.stapling.pem

prep: sub.domain.tld.key sub.domain.tld.pem startssl.stapling.pem

install: sub.domain.tld.key sub.domain.tld.pem startssl.stapling.pem
	cp sub.domain.tld.key /etc/ssl/private/
	cp sub.domain.tld.pem /etc/ssl/certs/
	cp startssl.stapling.pem /etc/ssl/certs/

installss: selfsigned.pem sub.domain.tld.key
	cp sub.domain.tld.key /etc/ssl/private/
	cp selfsigned.pem /etc/ssl/certs/sub.domain.tld.pem
