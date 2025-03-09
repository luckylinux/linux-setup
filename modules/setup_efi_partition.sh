#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source $toolpath/load.sh

# Standalone EFI/ESP Setup
for disk in "${disks[@]}"
do
    # Create Filesystem
    echo "Creating FAT32 filesystem on /dev/disk/by-id/${disk}-part${efi_num}"
    mkfs.vfat -F 32 "/dev/disk/by-id/${disk}-part${efi_num}"
    sleep 1
done

# EFI Software Raid if more than 1 Disk is used
# if [ ${numdisks_total} -eq 1 ]
# then
#    # Use FAT32 directly
#    # Create Filesystem
#    echo "Creating FAT32 filesystem on ${devices[0]}-part${efi_num}"
#    mkfs.vfat -F 32 "${devices[0]}-part${efi_num}"
#    sleep 1
# 
# elif [ ${numdisks_total} -eq 2 ]
# then
#    # Use MDADM
#    mdadm --create --verbose --metadata=0.90 /dev/${mdadm_efi_device} --level=1 --raid-devices=${numdisks_total} "${devices[0]}-part${efi_num}" "${devices[1]}-part${efi_num}"
#    sleep 1
# 
#    # Create Filesystem
#    echo "Creating FAT32 filesystem on /dev/${mdadm_efi_device}"
#    mkfs.vfat -F 32 "/dev/${mdadm_efi_device}"
#    sleep 1
# fi
