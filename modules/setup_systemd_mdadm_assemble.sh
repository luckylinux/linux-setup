#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Copy bin file
cp files/bin/mdadm-assemble $destination/usr/local/bin/
chmod +x destination/usr/local/bin/mdadm-assemble

# Copy Systemd file
cp files/systemd/mdadm-assemble.service	$destination/etc/systemd/system/mdadm-assemble.service

# Reload daemon
systemctl daemon-reload

# Enable service
systemctl enable mdadm-assemble.service
