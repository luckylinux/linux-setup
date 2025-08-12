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
timestamp_long=$(date +"%Y%m%d-%H%M%S")

# Backup Current /boot partition content
cd /boot
tar cvzf /boot_${timestamp_long}.tar.gz ./
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

# Move /boot to /boot_local_${timestamp_long}
chattr -i /boot
mv /boot /boot_local_${timestamp_long}

# Create /boot folder and prevent direct writing (i.e. a partition must first be mounted inside to enable writing)
mkdir -p /boot
chattr +i /boot

# Configure FSTAB
source ${toolpath}/modules/configure_boot_partition.sh

# Mount the newly created boot device
mount /boot

# Restore Backup
tar xvzf /boot_${timestamp_long}.tar.gz -C /boot

# Remove existing Pool Configuration if existing
if [[ -f "/etc/zfs/zfs-list.cache/bpool" ]]
then
    rm /etc/zfs/zfs-list.cache/bpool
fi

# Fore Bootloader Installation from Live System
export force_bootloader_installation_from_running_system="yes"
source ${toolpath}/inside-chroot/install_bootloader.sh

# Update Grub
update-grub

# Update Initramfs
update-initramfs -k all -u

# Update Grub
update-grub
