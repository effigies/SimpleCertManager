This script grew, as many a script does, out of looking up and repeating the
same actions, in this case for creating and managing SSL certificates for a
number of sites. The production of a certificate is reasonable managed with
Makefiles, so this script creates a directory for a site and generates a
Makefile and config file for that site.

The script, as it stands, assumes you'll be submitting signing requests (CSRs)
to [StartSSL](https://www.startssl.com/).

Typical workflow:

    ./update_site.sh sub.domain.tld
    pushd sub.domain.tld
        make csr
        # Copy CSR into StartSSL and save certificate as local.pem
        make prep
        sudo make install
        make nginx-pins
    popd

This installs a certificate for `sub.domain.tld` to `/etc/ssl/certs`, a private
key to `/etc/ssl/private`, and adds an OCSP-stapling trust chain, in case
you're into that.

The `nginx-pins` part will produce a backup key and a line to add to an
[nginx](http://nginx.org/) configuration to enable public-key pinning.

To replace the key, whether due to expiration or revocation:

    pushd sub.domain.tld
        make renew
        # Copy new CSR into StartSSL and save new cert as local.pem
        make prep
        sudo make install
        make nginx-pins
    popd

The old key and certificates are now in a folder marked with the current date
and a new key has been installed and a new backup key created.

Self-signing is also an option:

    pushd sub.domain.tld
        make selfsign
        sudo make installss
    popd

This uses the same keys, so creating a CSR and replacing a self-signed
certificate is the same as described above.
