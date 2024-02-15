#!/bin/bash

# Load Configuration
source ../config.sh

if [ "$bootfs" == "zfs" ]
then
        # Set partition type for the first disk
        # Redundant - Was already done above
        #sgdisk -t BF01 "${device1}"
        #sleep 1

        # Check if it's a single disk or a mirror RAID
        if [ "$numdisks" -eq 1 ]
        then
                devicelist="${device1}-part3"
        else if [ "$numdisks" -eq 2 ]
                # Set partition type also for the second disk
                # Redundant - Was already done above
                #sgdisk -t BF01 "${device2}"
                #sleep 1

                devicelist="mirror ${device1}-part3 ${device2}-part3"
        else
        then
                echo "Only single disks and mirror / RAID-1 setups are currently supported. Aborting !"
                exit 1
        fi

    # Create boot pool
    zpool create -f \
       -o ashift=$ashift -d \
       -o dnodesize=legacy \
       -o feature@async_destroy=enabled \
       -o feature@bookmarks=enabled \
       -o feature@embedded_data=enabled \
       -o feature@empty_bpobj=enabled \
       -o feature@enabled_txg=enabled \
       -o feature@extensible_dataset=enabled \
       -o feature@filesystem_limits=enabled \
       -o feature@hole_birth=enabled \
       -o feature@large_blocks=enabled \
       -o feature@lz4_compress=enabled \
       -o feature@spacemap_histogram=enabled \
       -o feature@zpool_checkpoint=enabled \
       -o compatibility=grub2 \
       -o cachefile=/etc/zfs/zpool.cache \
       -o dnodesize=legacy \
       -o autotrim=on \
       -O acltype=posixacl -O canmount=off -O compression=lz4 \
       -O devices=off -O normalization=formD -O relatime=on -O xattr=sa \
       -O mountpoint=/boot -R "$destination" \
       $bootpool $devicelist

    # Create datasets
    zfs create -o canmount=off -o mountpoint=none $bootpool/BOOT
    zfs create -o mountpoint=/boot $bootpool/BOOT/$distribution
else
then

        if [ $numdisks -eq 2 ]
        then
                # Dual Disk
                # Setup MDADM RAID1 / mirror EXT4 Software Raid

                # Set partition type
                # Redundant - Was already done above
                #sgdisk -t 8300 "${device1}-part3"
                sleep 1

                # Create filesystem
                mkfs.ext4  "${device1}-part3"

                # Set partition type
                # Redundant - Was already done above
                #sgdisk -t 8300 "${device2}-part3"
                sleep 1

                # Create filesystem
                mkfs.ext4  "${device2}-part3"

                # Assemble MDADM Array
                mdadm --create --verbose --metadata=0.90 /dev/md2 --level=1 --raid-devices=$numdisks "${device1}-part3" "${device2}-part3"
        else if [ $numdisks -eq 1 ]
                # Single Disk
                # Use EXT4 Directly
                
                # Set partition type
                # Redundant - Was already done above
                #sgdisk -t 8300 "${device1}-part3"
                #sleep 1

                # Create filesystem
                mkfs.ext4  "${device1}-part3"
        fi
fi
