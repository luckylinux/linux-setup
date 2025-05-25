#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

#echo "blocked" > /sys/block/md0/md/rd1/state
#echo "faulty" > /sys/block/md0/md/rd1/state
#echo "removed" > /sys/block/md0/md/rd1/state

# This module only deals with /boot and /boot/efi and can thus be executed on a live system
# Better to avoid touching this until all existing Devices from all Systems have been disconnected from mdadm and converted into standalone EFI/ESP Partitions
if [ -e "/dev/${mdadm_efi_device}" ]
then
   umount -q /dev/${mdadm_efi_device}

   echo "Remove disks from /dev/${mdadm_efi_device}"
   mdadm --stop /dev/${mdadm_efi_device}
   echo "idle" >  /sys/block/${mdadm_efi_device}/md/sync_action

   for disk in "${disks[@]}"
   do
       mdadm /dev/${mdadm_efi_device} --fail "/dev/disk/by-id/${disk}-part${efi_num}"

       mdadm /dev/${mdadm_efi_device} --remove "/dev/disk/by-id/${disk}-part${efi_num}"
   done

   echo "Stopping /dev/${mdadm_efi_device}"
   mdadm --stop /dev/${mdadm_efi_device}
fi

if [ -e "/dev/${mdadm_boot_device}" ]
then
   umount -q /dev/${mdadm_boot_device}

   echo "Remove disks from /dev/${mdadm_boot_device}"
   mdadm --stop /dev/${mdadm_boot_device}
   echo "idle" >  /sys/block/${mdadm_boot_device}/md/sync_action

   for disk in "${disks[@]}"
   do
       mdadm ${mdadm_boot_device} --fail "/dev/disk/by-id/${disk}-part${boot_num}"

       mdadm ${mdadm_boot_device} --remove "/dev/disk/by-id/${disk}-part${boot_num}"
   done

   echo "Stopping /dev/${mdadm_boot_device}"
   mdadm --stop /dev/${mdadm_boot_device}
fi

if [ -e "/dev/${mdadm_root_device}" ]
then
   umount -q /dev/${mdadm_root_device}

   echo "Remove disks from /dev/${mdadm_root_device}"
   mdadm --stop /dev/${mdadm_root_device}
   echo "idle" >  /sys/block/${mdadm_root_device}/md/sync_action

   for disk in "${disks[@]}"
   do
       mdadm ${mdadm_root_device} --fail "/dev/disk/by-id/${disk}-part${root_num}"

       mdadm ${mdadm_root_device} --remove "/dev/disk/by-id/${disk}-part${root_num}"
   done

   echo "Stopping /dev/${mdadm_root_device}"
   mdadm --stop /dev/${mdadm_root_device}
fi

if [ -e "/dev/${mdadm_data_device}" ]
then
   umount -q /dev/${mdadm_data_device}

   echo "Remove disks from /dev/${mdadm_data_device}"
   mdadm --stop /dev/${mdadm_data_device}
   echo "idle" >  /sys/block/${mdadm_data_device}/md/sync_action

   for disk in "${disks[@]}"
   do
      mdadm ${mdadm_data_device} --fail "/dev/disk/by-id/${disk}-part${data_num}"

      mdadm ${mdadm_data_device} --remove "/dev/disk/by-id/${disk}-part${data_num}"
   done

   echo "Stopping /dev/${mdadm_data_device}"
   mdadm --stop /dev/${mdadm_data_device}
fi

# Umount all "rogue" MDADM Devices that were started automatically when the System was booted
mapfile mdadm_devices < <(find /sys/class/block -iname md* | sed -E "s|.+/md([0-9]+)$|md\1|g")

for mdadm_device in "${mdadm_devices[@]}"
do
    umount -q /dev/${mdadm_device}

    echo "Stop MDADM Device /dev/${mdadm_device}"
    echo "idle" >  /sys/block/${mdadm_device}/md/sync_action

    # Stop Slaves
    mapfile mdadm_device_slaves < <(find /sys/devices/virtual/block/${mdadm_device}/slaves -mindepth 1 | sed -E "s|.+/slaves/([a-z0-9]+)$|\1|g")
    for mdadm_device_slave in "${mdadm_device_slaves[@]}"
    do
         mdadm ${mdadm_device} --fail "${mdadm_device_slave}"
         mdadm ${mdadm_device} --remove "${mdadm_device_slave}"
    done

    # Stop MDADM Array
    mdadm --stop /dev/${mdadm_device}
done
