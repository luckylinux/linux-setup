#!/bin/bash

# References:
# - https://github.com/jakeday/linux-surface/blob/3267e4ea1f318bb9716d6742d79162de8277dea2/SIGNING.md

# Install Requirements
apt-get install mokutil

# Define Base Folder
basefolder="/etc/mokutil"

# Create Folder if it doesn't exist yet
mkdir -p "${basefolder}"

# Create Mokutil Configuration Folder
mkdir -p /etc/mokutil

# Create Mokutil Template Configuration File
if [ ! -f "/etc/mokutil/mokconfig.cnf" ]
then
tee /etc/mokutil/mokconfig.cnf << EOF
# This definition stops the following lines choking if HOME isn't
# defined.
HOME                    = .
RANDFILE                = $ENV::HOME/.rnd
[ req ]
distinguished_name      = req_distinguished_name
x509_extensions         = v3
string_mask             = utf8only
prompt                  = no

[ req_distinguished_name ]
countryName             = <COUNTRY_CODE>
stateOrProvinceName     = <STATE>
localityName            = <CITY_OR_LOCALITY>
0.organizationName      = <ORG_NAME>
commonName              = Secure Boot Signing
emailAddress            = secure@<MYDOMAIN>.<TLD>

[ v3 ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer
basicConstraints        = critical,CA:FALSE
extendedKeyUsage        = codeSigning,1.3.6.1.4.1.311.10.3.6,1.3.6.1.4.1.2312.16.1.2
nsComment               = "OpenSSL Generated Certificate"
EOF
fi

# Install nano if not installed yet
if [[ -z $(command -v nano) ]]
then
    apt-get update
    apt-get install nano
fi

# Open the File for editing in Interactive Mode
nano /etc/mokutil/mokconfig.cnf

# Create Rand File if it doesn't exist
openssl rand -writerand /root/.rnd

# Generate Signing Keys
# Create the public and private key for signing the kernel
openssl req -config "${basefolder}/mokconfig.cnf" \
        -new -x509 -newkey rsa:4096 \
        -nodes -days 36500 -outform DER \
        -keyout "${basefolder}/MOK.priv" \
        -out "${basefolder}/MOK.der"

# Convert the key also to PEM format (mokutil needs DER, sbsign needs PEM)
openssl x509 -in "${basefolder}/MOK.der" -inform DER -outform PEM -out "${basefolder}/MOK.pem"

# Enroll the key to your shim installation
# You will be asked for a password, you will just use it to confirm your key selection in the next step, so choose any
echo "You will need to enter a Passphrase to enroll the Secure Boot Keys at next Boot !"
sudo mokutil --import "${basefolder}/MOK.der"

# Copy MOK.der and MOK.priv to /var/lib/shim-signed/mok/
cp "${basefolder}/MOK.der" /var/lib/shim-signed/mok/MOK.der
cp "${basefolder}/MOK.priv" /var/lib/shim-signed/mok/MOK.priv

# Get a Recent Version (>= 3.1.0 of DKMS that supports the "generate_mok" Command
mkdir -p /usr/local/sbin
wget https://raw.githubusercontent.com/dell/dkms/refs/tags/v3.1.6/dkms.in -O /usr/local/sbin/dkms_with_mok
chmod +x /usr/local/sbin/dkms_with_mok

# Setup DKMS
/usr/local/sbin/dkms_with_mok generate_mok

# Update InitramFS and Grub
update-initramfs -k all -u
update-grub
update-initramfs -k all -u
update-grub
