#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Copy bin file
cp $toolpath/files/bin/mdadm-assemble $destination/usr/local/bin/
chmod +x $destination/usr/local/bin/mdadm-assemble

# Copy Systemd file
cp $toolpath/files/systemd/mdadm-assemble.service $destination/etc/systemd/system/mdadm-assemble.service

# Disable UDEV automatic assembly of mdadm arrays
# AUTO -all in /etc/mdadm/mdadm.conf is NOT sufficient

# This by itself is NOT sufficient
ln -s /dev/null /etc/udev/rules.d/64-md-raid-assembly.rules

# This SOLVED the issue about udev automatically assembling (with a different name than is desired) mdadm arrays
mkdir -p /lib/udev/rules.d.disabled
mv /lib/udev/rules.d/64-md-raid-assembly.rules /lib/udev/rules.disabled/64-md-raid-assembly.rules

# Reload daemon
systemctl daemon-reload

# Enable service
systemctl enable mdadm-assemble.service
