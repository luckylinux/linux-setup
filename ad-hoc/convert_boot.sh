#!/bin/bash

# Abort on errors
set -e

# Load configuration
source ../config.sh

# Mount Current /boot partition
mount /boot

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d")

# Backup Current /boot partition content
tar cvzf /boot_$timestamp.tar.gz /boot

# Check if ZFS boot pool exists
# If so, export it
v=$(zpool list | grep $bootpool | tail -n1)
if [ "$v" == "" ]
then
   echo "Unmount ZFS boot pool <$bootpool>"
   zpool export $bootpool
fi

# Execute Boot Device(s) Setup
source ../modules/setup_boot_partition.sh

# Restore Backup
tar xvzf /boot_$timestamp.tar.gz -C /boot
