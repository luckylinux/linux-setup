#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load config
source $toolpath/config.sh

# Wait a few seconds
sleep 5

# Determine Root device(s)
# Path / Device changes whether encryption is used or not
if [ "$encryptrootfs" == "no" ]
then
        firstdevice="/dev/disk/by-id/${disk1}-part4"
        seconddevice="/dev/disk/by-id/${disk2}-part4"
elif [ "$encryptrootfs" == "luks" ]
then
        firstdevice="/dev/mapper/${disk1}_crypt"
        seconddevice="/dev/mapper/${disk2}_crypt"
else
        echo "Encryption mode <${encryptrootfs}> for / is NOT supported. Aborting !"
        exit 1
fi

if [ "$rootfs" == "zfs" ]
then
        # Check if it's a single disk or a mirror RAID
        if [ "$numdisks" -eq 1 ]
        then
                devicelist="$firstdevice"
        elif [ "$numdisks" -eq 2 ]
        then
                devicelist="mirror $firstdevice $seconddevice"
        else
                echo "Only single disks and mirror / RAID-1 setups are currently supported. Aborting !"
                exit 1
        fi

        # Create root pool
        zpool create -f -o ashift=$ashift \
        -O acltype=posixacl -O canmount=off -O compression=lz4 \
        -O dnodesize=auto -O normalization=formD -O relatime=on \
        -O xattr=sa \
        -O mountpoint=/ -R "$destination" \
        $rootpool $devicelist

else
        if [ $numdisks -eq 2 ]
        then
                # Setup MDADM RAID1 / mirror EXT4 Software Raid

                # Assemble MDADM Array
                mdadm --create --verbose /dev/${mdadm_root_device} --level=1 --raid-devices=$numdisks "${firstdevice}" "${seconddevice}"

                # Dual Disk
		mkfs.ext4 "/dev/${mdadm_root_device}"
        elif [ $numdisks -eq 1 ]
        then
                # Single Disk
                # Use EXT4 Directly

                # Create filesystem
                mkfs.ext4 "${firstdevice}"
        fi
fi

# Wait a few seconds
sleep 5
