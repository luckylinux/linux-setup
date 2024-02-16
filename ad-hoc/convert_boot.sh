#!/bin/bash

# Do NOT Abort on errors
#set -e

# Load configuration
source ../config.sh

# Mount Current /boot partition
mount /boot

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d")

# Backup Current /boot partition content
#cd /boot
#tar cvzf /boot_$timestamp.tar.gz ./
#cd ..

# Check if ZFS boot pool exists
# If so, export it
v=$(zpool list | grep $bootpool | tail -n1)
if [ ! "$v" == "" ]
then
   echo "Unmount ZFS boot pool <$bootpool>"
   zpool export $bootpool
fi

# Execute Boot Device(s) Setup
source $toolpath/modules/setup_boot_partition.sh

# Move /boot to /boot_local_$timestamp
#chattr -i /boot
#mv /boot /boot_local_$timestamp

# Create /boot folder and prevent direct writing (i.e. a partition must first be mounted inside to enable writing)
mkdir -p /boot
chattr +i /boot

# Configure FSTAB
source $toolpath/modules/configure_boot_partition.sh

# Mount the newly created boot device
mount /boot

# Restore Backup
tar xvzf /boot_$timestamp.tar.gz -C /boot
