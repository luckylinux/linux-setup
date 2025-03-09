#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
source $toolpath/load.sh

# Wait a few seconds
sleep 5

# Determine Root device(s)
# Path / Device changes whether encryption is used or not
if [ "$encryptrootfs" == "no" ]
then
        firstdevice="/dev/disk/by-id/${disk1}-part${root_num}"
        seconddevice="/dev/disk/by-id/${disk2}-part${root_num}"
elif [ "$encryptrootfs" == "luks" ]
then
        firstdevice="/dev/mapper/${disk1}_root_crypt"
        seconddevice="/dev/mapper/${disk2}_root_crypt"
else
        echo "Encryption mode <${encryptrootfs}> for / is NOT supported. Aborting !"
        exit 1
fi

if [ "$rootfs" == "zfs" ]
then
        # Check if it's a single disk or a mirror RAID
        if [ "${numdisks_total}" -eq 1 ]
        then
                if [ "$encryptrootfs" == "no" ]
                then
                        devicelist="/dev/disk/by-id/${disks[0]}-part${root_num}"
                elif [ "$encryptrootfs" == "luks" ]
                then
                        devicelist="/dev/mapper/${disks[0]}_root_crypt"
                fi
        else
                # Build Device List (for the First Stripe)
                devicelist="${rootpool_type_each_vdev}"
                for disk_counter in $(seq 1 ${rootpool_number_disks_each_vdev})
                do
                    disk_index=$((disk_counter - 1))
                    disk=${disks[${disk_index}]}
                    if [ "$encryptrootfs" == "no" ]
                    then
                        devicelist="${devicelist} /dev/disk/by-id/${disk}-part${root_num}"
                    elif [ "$encryptrootfs" == "luks" ]
                    then
                        devicelist="${devicelist} /dev/mapper/${disk}_root_crypt"
                    fi
                done

        fi
        # else
        #         echo "Only single disks and mirror / RAID-1 setups are currently supported. Aborting !"
        #         exit 1
        # fi

        # Create root pool
        zpool create -f -o ashift=$ashift -o compatibility=openzfs-2.0-linux \
        -O acltype=posixacl -O canmount=off -O compression=lz4 \
        -O dnodesize=auto -O normalization=formD -O relatime=on \
        -O xattr=sa \
        -O mountpoint=/ -R "$destination" \
        $rootpool $devicelist

        sleep 1

        # Add Further VDEVs if rootpool_number_stripes > 1
        if [ ${rootpool_number_stripes} -gt 1 ]
        then
            for stripe_counter in $(seq 2 ${rootpool_number_stripes})
            do
                # Build Device List
                devicelist="${rootpool_type_each_vdev}"

                for disk_counter in $(seq $(((stripe_counter-1)*rootpool_number_disks_each_vdev+1)) $((stripe_counter*rootpool_number_disks_each_vdev)))
                do
                    disk_index=$((disk_counter - 1))
                    disk=${disks[${disk_index}]}

                    if [ "$encryptrootfs" == "no" ]
                    then
                        devicelist="${devicelist} /dev/disk/by-id/${disk}-part${root_num}"
                    elif [ "$encryptrootfs" == "luks" ]
                    then
                        devicelist="${devicelist} /dev/mapper/${disk}_root_crypt"
                    fi
                done

                # Add new VDEV to the Pool
                zpool add -o ashift=${ashift} ${rootpool} ${devicelist}

                sleep 1
            done
        fi

else
        if [ ${numdisks_total} -eq 1 ]
        then
                # Single Disk
                # Use EXT4 Directly

                # Create filesystem
                if [ "$encryptrootfs" == "no" ]
                then
                    mkfs.ext4 "/dev/disk/by-id/${disk}-part${root_num}"
                elif [ "$encryptrootfs" == "luks" ]
                then
                    mkfs.ext4 "/dev/mapper/${disk}_root_crypt"
                fi
        else
                # Setup MDADM RAID1 / mirror EXT4 Software Raid

                devicelist=""
                # Build Device List
                for disk in "${disks[@]}"
                do
                    if [ "$encryptrootfs" == "no" ]
                    then
                        devicelist="${devicelist} /dev/disk/by-id/${disk}-part${root_num}"
                    elif [ "$encryptrootfs" == "luks" ]
                    then
                        devicelist="${devicelist} /dev/mapper/${disk}_root_crypt"
                    fi

                    # Create filesystem
                    #mkfs.ext4  "/dev/disk/by-id/${disk}-part${boot_num}"
                done

                # Assemble MDADM Array
                mdadm --create --verbose /dev/${mdadm_root_device} --level=${rootpool_type_each_vdev} --raid-devices=${numdisks_total} "${firstdevice}" "${seconddevice}"

                # Dual Disk
		mkfs.ext4 "/dev/${mdadm_root_device}"
        fi
fi

# Wait a few seconds
sleep 5
