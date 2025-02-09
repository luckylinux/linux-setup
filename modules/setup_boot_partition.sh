#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source $toolpath/load.sh

if [ "$bootfs" == "zfs" ]
then
        # Set partition type for the first disk
        # Might already have been done during setup, but still calling it here in case of e.g. /boot partition conversion
        sgdisk -t BF01 "${device1}"
        sleep 1

        # Check if it's a single disk or a mirror RAID
        if [ "$numdisks" -eq 1 ]
        then
                devicelist="${device1}-part${boot_num}"
        elif [ "$numdisks" -eq 2 ]
        then
                # Set partition type also for the second disk
                # Might already have been done during setup, but still calling it here in case of e.g. /boot partition conversion
                sgdisk -t BF01 "${device2}"
                sleep 1

                devicelist="mirror ${device1}-part${boot_num} ${device2}-part${boot_num}"
        else
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
    zfs create -o mountpoint=/boot $bootpool/BOOT/$DISTRIBUTION

elif [ "$bootfs" == "ext4" ]
then
        if [ "$numdisks" -eq 2 ]
        then
                # If running in CHROOT then make sure to setup required packages
                if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]
                then
			apt-get install --yes mdadm
	        fi

                # Dual Disk
                # Setup MDADM RAID1 / mirror EXT4 Software Raid

                # Set partition type
                # Might already have been done during setup, but still calling it here in case of e.g. /boot partition conversion
                sgdisk -t 8300 "${device1}-part${boot_num}"
                sleep 1

                # Create filesystem
                #mkfs.ext4  "${device1}-part${boot_num}"

                # Set partition type
                # Might already have been done during setup, but still calling it here in case of e.g. /boot partition conversion
                sgdisk -t 8300 "${device2}-part${boot_num}"
                sleep 1

                # Create filesystem
                #mkfs.ext4  "${device2}-part${boot_num}"

                # Assemble MDADM Array
                echo "Assembling MDADM RAID1 array for boot device"
                mdadm --create --verbose --metadata=0.90 /dev/${mdadm_boot_device} --level=1 --raid-devices=$numdisks "${device1}-part${boot_num}" "${device2}-part${boot_num}"
                sleep 1

                # Create filesystem
                mkfs.ext4 "/dev/${mdadm_boot_device}"

        elif [ "$numdisks" -eq 1 ]
        then
                # Single Disk
                # Use EXT4 Directly

                # Set partition type
                # Might already have been done during setup, but still calling it here in case of e.g. /boot partition conversion
                sgdisk -t 8300 "${device1}-part${boot_num}"
                sleep 1

                # Create filesystem
                mkfs.ext4  "${device1}-part${boot_num}"
        else
                echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
                exit 1
        fi

else
        echo "Only ZFS and EXT4 are currently supported. Aborting !"
        exit 1
fi
