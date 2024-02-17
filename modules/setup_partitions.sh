#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load config
source $toolpath/config.sh

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
	mdadm --zero-superblock --force "${device}-part${efi_num}" >> $n
	mdadm --zero-superblock --force "${device}-part${boot_num}" >> $n
	mdadm --zero-superblock --force "${device}-part${root_num}" >> $n

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

	echo "Creating BIOS partition on ${device}-part${bios_num}"

	parted --align=opt $device mkpart primary "${start_bios}MiB" "${end_bios}MiB" >> $n
	parted $device name 1 "${label}_BIOS" >> $n
	parted $device set 1 bios_grub on >> $n

        # EFI Partition
        start_efi=$((end_bios))
	end_efi=$((start_efi + efi_size)) # MiB

	echo "Creating EFI partition on ${device}-part${efi_num}"

	parted --align=opt $device mkpart ESI fat32 "${start_efi}MiB" "${end_efi}MiB" >> $n
	parted $device name 2 "${label}_EFI" >> $n
	parted $device toggle 2 msftdata >> $n
	parted $device set 2 boot on >> $n

        # Wait a few seconds
        sleep 2

	#echo "Creating FAT32 filesystem on ${device}-part${efi_num}"
	#mkfs.vfat -F 32 "${device}-part${efi_num}"

	# Wait a few seconds
	#sleep 1

	# Setup /boot partition
	start_boot=$((end_efi))		 # MiB
	end_boot=$((start_boot + boot_size)) # MiB

	echo "Creating /boot partition on ${device}-part${bios_num}"
	parted --align=opt $device mkpart primary "${start_boot}MiB" "${end_boot}MiB" >> $n
	parted $device name 3 "${label}_BOOT" >> $n

	# Setup / partition
	start_root=$((end_boot))		 # MiB
	end_root=$((disk_size - margin_size)) # MiB

	echo "Creating / partition on ${device}-part${root_num}"
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
            #mkfs.ext4  "${device}-part${bios_num}"
        elif [ "$bootfs" == "zfs" ]
        then
           # Set partition type
           sgdisk -t BF01 "${device}"
        else
           # Filesystem for /boot not supported
           echo "Filesystem for /boot not supported. Aborting"
           exit 1
        fi

        # Wait a few seconds
        sleep 1

	# Encrypt root
        # Need to get the short disk name / device name
        disk="${disks[$counter]}"

        if [ "$encryptrootfs" == "no" ]
        then
                echo "Skip Encryption Process"
        elif [ "$encryptrootfs" == "luks" ]
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

                      if [ "$password" != "$verify" ]
                      then
                             echo "Password Verification failed - Password do NOT match"
                      else
                             echo "Password Verification successful"
                      fi
                done
        else
                echo "Encryption mode <${encryptrootfs}> for / is NOT supported. Aborting !"
                exit 1
        fi

        echo $password | cryptsetup -q -v --type luks2 --cipher aes-xts-plain64 --hash sha512 --key-size 512 --use-random --iter-time 5000 luksFormat "${device}-part${root_num}"
        echo -n $password | cryptsetup open --type luks2 "${device}-part${root_num}" "${disk}_crypt"
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

# Setup EFI Partition / RAID1
source $toolpath/modules/setup_efi_partition.sh

# Setup /boot Partition / RAID1
source $toolpath/modules/setup_boot_partition.sh

# Setup / Partition / RAID1
source $toolpath/modules/setup_root_partition.sh

# Configure root partition
# PROBABLY NOT CORRECT, SINCE IT WILL AFFECT THE HOST, NOT THE CHROOT ENVIRONMENT !
source $toolpath/modules/configure_root_partition.sh
