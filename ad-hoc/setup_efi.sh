#!/bin/bash

# Do NOT Abort on errors
#set -e

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/load.sh

# Mount Current /boot partition
mount /boot

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d")

# Execute EFI Device(s) Setup
source $toolpath/modules/setup_efi_partition.sh

# Create /boot/efi Folder
mkdir -p /boot/efi

# Allow direct writing to the Folder
chattr -i /boot/efi

# Create a Subfolder for each Disk ESP/EFI Partition
for disk in "${disks[@]}"
do
    mkdir -p "/boot/efi/${disk}"
    chattr +i "/boot/efi/${disk}"
done

# Configure FSTAB
source $toolpath/modules/configure_efi_partition.sh

# Mount the newly created ESP/EFI device
for disk in "${disks[@]}"
do
    mount "/boot/efi/${disk}"
done
