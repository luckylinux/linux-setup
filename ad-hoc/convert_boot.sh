#!/bin/bash

# Do NOT Abort on errors
#set -e

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Install Requirements
apt-get install bc mdadm lsb-release

# Override Destination since this is NOT an Installation but rather an in-place Update on a running (live) System
export destination="/"

# Mount Current /boot partition
mount /boot

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d-%H%M%S")

# Backup Current /boot partition content
cd /boot
tar cvzf /boot_$timestamp.tar.gz ./
cd ..

# Check if ZFS boot pool exists
# If so, export it
v=$(zpool list | grep ${bootpool} | tail -n1)
if [ ! "$v" == "" ]
then
   echo "Unmount ZFS boot pool <${bootpool}>"
   zpool export ${bootpool}
fi

# Execute Boot Device(s) Setup
source ${toolpath}/modules/setup_boot_partition.sh

# Move /boot to /boot_local_$timestamp
chattr -i /boot
mv /boot /boot_local_$timestamp

# Create /boot folder and prevent direct writing (i.e. a partition must first be mounted inside to enable writing)
mkdir -p /boot
chattr +i /boot

# Configure FSTAB
source ${toolpath}/modules/configure_boot_partition.sh

# Mount the newly created boot device
mount /boot

# Restore Backup
tar xvzf /boot_$timestamp.tar.gz -C /boot

# Update Grub
update-grub

# Update Initramfs
update-initramfs -k all -u

# Update Grub
update-grub
