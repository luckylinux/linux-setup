#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
source $toolpath/load.sh

# Wait a few seconds
sleep 5

# Determine Data device(s)
# Path / Device changes whether encryption is used or not
if [ "$encryptdatafs" == "no" ]
then
        firstdevice="/dev/disk/by-id/${disk1}-part${data_num}"
        seconddevice="/dev/disk/by-id/${disk2}-part${data_num}"
elif [ "$encryptdatafs" == "luks" ]
then
        firstdevice="/dev/mapper/${disk1}_data_crypt"
        seconddevice="/dev/mapper/${disk2}_data_crypt"
else
        echo "Encryption mode <${encryptdatafs}> for / is NOT supported. Aborting !"
        exit 1
fi

if [ "$datafs" == "zfs" ]
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

        # Create data pool
        zpool create -f -o ashift=$ashift -o compatibility=openzfs-2.0-linux \
        -O acltype=posixacl -O canmount=off -O compression=lz4 \
        -O dnodesize=auto -O normalization=formD -O relatime=on \
        -O xattr=sa \
        -O mountpoint=/data -R "$destination" \
        $datapool $devicelist

else
        if [ $numdisks -eq 2 ]
        then
                # Setup MDADM RAID1 / mirror EXT4 Software Raid

                # Assemble MDADM Array
                mdadm --create --verbose /dev/${mdadm_data_device} --level=1 --raid-devices=$numdisks "${firstdevice}" "${seconddevice}"

                # Dual Disk
		mkfs.ext4 "/dev/${mdadm_data_device}"
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
