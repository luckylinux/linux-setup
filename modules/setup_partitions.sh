#!/bin/bash

# Load config
source ../config.sh

# Erase all partitions
echo "=================================================================================================="
echo "====================================== INIT DISKS ================================================"
echo "=================================================================================================="
for device in "${devices[@]}"
do
	# Display device informations
	parted $device unit MiB print

	# Ask about erasing all partitions from it
	while true; do
		read -p "Erase all partitions on $device ? [y / n] " answer
		case $answer in
			[Yy]* ) break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
	echo "=================================================================================================="
done
wait

# Setup partitioning for each HDD
echo "=================================================================================================="
echo "==================================== SETUP DISKS PARTITIONING ===================================="
echo "=================================================================================================="
counter=0
for device in "${devices[@]}"
do
	# Get label
	label="${labels[$counter]}"

	# Clear superblock if mdadm was used previously
	mdadm --zero-superblock --force "${device}-part2" >> $n
	mdadm --zero-superblock --force "${device}-part3" >> $n
	mdadm --zero-superblock --force "${device}-part4" >> $n

	# Pause
	sleep 1

	# Clear the partition table
	sgdisk --zap-all "$device" >> $n

	# Pause
	sleep 1

	# Create GPT partitioning scheme
	parted -s $device mklabel GPT >> $n

	# Pause
	sleep 1

	# Setup BIOS / EFI partition
	# BIOS Partition
        start_bios=1 				# MiB
        end_bios=$((start_bios_efi + bios_size))	# MiB

	echo "Creating BIOS partition on ${device}-part1"

	parted --align=opt $device mkpart primary "${start_bios}MiB" "${end_bios}MiB" >> $n
	parted $device name 1 "${label}_BIOS" >> $n
	parted $device set 1 bios_grub on >> $n

        # EFI Partition
        start_efi=$((end_bios))
	end_efi=$((start_efi + efi_size)) # MiB

	echo "Creating EFI partition on ${device}-part2"

	parted --align=opt $device mkpart ESI fat32 "${start_efi}MiB" "${end_efi}MiB" >> $n
	parted $device name 2 "${label}_EFI" >> $n
	parted $device toggle 2 msftdata >> $n
	parted $device set 2 boot on >> $n

        # Wait a few seconds
        sleep 2

	echo "Creating FAT32 filesystem on ${device}-part2"
	mkfs.vfat -F 32 "${device}-part2"

	# Wait a few seconds
	sleep 1

	# Setup /boot partition
	start_boot=$((end_efi))		 # MiB
	end_boot=$((start_boot + boot_size)) # MiB

	echo "Creating /boot partition on ${device}-part3"
	parted --align=opt $device mkpart primary "${start_boot}MiB" "${end_boot}MiB" >> $n
	parted $device name 3 "${label}_BOOT" >> $n

	# Setup / partition
	start_root=$((end_boot))		 # MiB
	end_root=$((disk_size - margin_size)) # MiB

	echo "Creating / partition on ${device}-part4"
	parted --align=opt $device mkpart primary "${start_root}MiB" "${end_root}MiB" >> $n
	parted $device name 4 "${label}_ROOT" >> $n
	sgdisk -t 8309 "${device}"

        if [ "$bootfs" == "ext4" ]
        then
            # Set partition type
            sgdisk -t 8300 "${device}"

            # Wait a few seconds
            sleep 1

            # Create filesystem
            mkfs.ext4  "${device}-part3"
        elif [ "$bootfs" == "zfs" ]
        then
           # Set partition type
           sgdisk -t BF01 "${device}"
        else    
        then
           # Filesystem for /boot not supported
           echo "Filesystem for /boot not supported. Aborting"
           exit 1
        fi

        # Wait a few seconds
        sleep 1

	# Encrypt root
        # Need to get the short disk name / device name
        disk="${disks[$counter]}"

        if [ "$encryptrootfs" == "no"]
        then
                echo "Skip Encryption Process"
        else if [ "$encryptrootfs" == "luks"]
        then
                # Ask for password
                # Initial values need to be intentionally different in order for the while loop to work correctly
                password="true"
                verify="false"
                while [ "$password" != "$verify" ]
                do
                read -s -p "Enter encryption password: " password
                echo ""
                read -s -p "Verify encryption password: " verify

                if [ "$password" != "$verify" ]; then
                echo "Password Verification failed - Password do NOT match"
                else
                echo "Password Verification successful"
                fi
                done
        else
        then
                echo "Encryption mode <${encryptrootfs}> for / is NOT supported. Aborting !"
                exit 1
        fi

        echo $password | cryptsetup -q -v --type luks2 --cipher aes-xts-plain64 --hash sha512 --key-size 512 --use-random --iter-time 5000 luksFormat "${device}-part4"
        echo -n $password | cryptsetup open --type luks2 "${device}-part4" "${disk}_crypt"
        unset $password
        unset $verify

	# Increment counter
	counter=$((counter+1))
done

# Setup RAID mirror (RAID-1)
echo "=================================================================================================="
echo "====================================== SETUP RAID ================================================"
echo "=================================================================================================="

sleep 5

# EFI Software Raid
if [ $numdisks -eq 1 ]
then
   # Use FAT32 directly
else if [ $numdisks -eq 2 ]
   # Use MDADM
   mdadm --create --verbose --metadata=0.90 /dev/md2 --level=1 --raid-devices=$numdisks "${device1}-part2" "${device2}-part2"
fi

# Setup boot Partition & RAID
source ./setup_boot_partition.sh

# Wait a few seconds
sleep 5

# Determine Root device(s)
# Path / Device changes whether encryption is used or not
if [ "$encryptrootfs" == "no"]
then
        firstdevice="/dev/disk/by-id/${disk1}-part4"
        seconddevice="/dev/disk/by-id/${disk2}-part4"
else if [ "$encryptrootfs" == "luks"]
        firstdevice="/dev/mapper/${disk1}_crypt"
        seconddevice="/dev/mapper/${disk2}_crypt"
else
then
        echo "Encryption mode <${encryptrootfs}> for / is NOT supported. Aborting !"
        exit 1
fi

if [ "$rootfs" == "zfs" ]
then
        # Check if it's a single disk or a mirror RAID
        if [ "$numdisks" -eq 1 ]
        then
                devicelist="$firstdevice"
        else if [ "$numdisks" -eq 2 ]
                devicelist="mirror $firstdevice $seconddevice"
        else
        then
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
then
        if [ $numdisks -eq 2 ]
        then
                # Dual Disk
                # Setup MDADM RAID1 / mirror EXT4 Software Raid

                # Create filesystem
                mkfs.ext4  "${firstdevice}"

                # Create filesystem
                mkfs.ext4  "${seconddevice}"

                # Assemble MDADM Array
                mdadm --create --verbose /dev/md3 --level=1 --raid-devices=$numdisks "${firstdevice}" "${seconddevice}"
        else if [ $numdisks -eq 1 ]
                # Single Disk
                # Use EXT4 Directly

                # Create filesystem
                mkfs.ext4  "${firstdevice}"
        fi
fi

# Wait a few seconds
sleep 5

if [ "$encryptrootfs" == "luks"]
then
        # Enable Disk in Crypttab for initramfs
        echo "${disk1}_crypt" UUID=$(blkid -s UUID -o value ${firstdevice}) none \
        luks,discard,initramfs > "${destination}/etc/crypttab"

        if [ $numdisks -eq 2 ]
        then
                echo "${disk2}_crypt" UUID=$(blkid -s UUID -o value ${seconddevice}) none \
                 luks,discard,initramfs >> "${destination}/etc/crypttab"
        fi
fi
