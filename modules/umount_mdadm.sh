#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh



#echo "blocked" > /sys/block/md0/md/rd1/state
#echo "faulty" > /sys/block/md0/md/rd1/state
#echo "removed" > /sys/block/md0/md/rd1/state

# This module only deals with /boot and /boot/efi and can thus be executed on a live system
if [ -e "/dev/${mdadm_efi_device}" ]
then
   echo "Remove disks from /dev/${mdadm_efi_device}"
   mdadm --stop /dev/${mdadm_efi_device}
   #echo "idle" >  /sys/block/${mdadm_efi_device}/md/sync_action
   mdadm /dev/${mdadm_efi_device} --fail "${device1}-part${efi_num}"
   mdadm /dev/${mdadm_efi_device} --fail "${device2}-part${efi_num}"
   mdadm /dev/${mdadm_efi_device} --remove "${device1}-part${efi_num}"
   mdadm /dev/${mdadm_efi_device} --remove "${device2}-part${efi_num}"
   echo "Stopping /dev/${mdadm_efi_device}"
   mdadm --stop /dev/${mdadm_efi_device}
fi

if [ -e "/dev/${mdadm_boot_device}" ]
then
   echo "Remove disks from /dev/${mdadm_boot_device}"
   mdadm --stop /dev/${mdadm_boot_device}
   echo "idle" >  /sys/block/${mdadm_boot_device}/md/sync_action
   mdadm ${mdadm_boot_device} --fail "${device1}-part${boot_num}"
   mdadm ${mdadm_boot_device} --fail "${device2}-part${boot_num}"
   mdadm ${mdadm_boot_device} --remove "${device1}-part${boot_num}"
   mdadm ${mdadm_boot_device} --remove "${device2}-part${boot_num}"
   echo "Stopping /dev/${mdadm_boot_device}"
   mdadm --stop /dev/${mdadm_boot_device}
fi
