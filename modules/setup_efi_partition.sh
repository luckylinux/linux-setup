#!/bin/bash

# Load Configuration
source $toolpath/config.sh

# EFI Software Raid if more than 1 Disk is used
if [ $numdisks -eq 1 ]
then
   # Use FAT32 directly
   # Create Filesystem
   echo "Creating FAT32 filesystem on $device1-part2"
   mkfs.vfat -F 32 "$device1-part2"
   sleep 1

   # Create Filesystem
   echo "Creating FAT32 filesystem on $device2-part2"
   mkfs.vfat -F 32 "$device2-part2"
   sleep 1


elif [ $numdisks -eq 2 ]
then
   # Use MDADM
   mdadm --create --verbose --metadata=0.90 /dev/${mdadm_efi_device} --level=1 --raid-devices=$numdisks "${device1}-part2" "${device2}-part2"
   sleep

   # Create Filesystem
   echo "Creating FAT32 filesystem on /dev/${mdadm_efi_device}"
   mkfs.vfat -F 32 "/dev/${mdadm_efi_device}"
   sleep 1
fi
