#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
source "${toolpath}/load.sh"

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

        if [[ $(command -v mdadm) ]]
        then
            # Clear superblock if mdadm was used previously
            if [[ -e "${device}-part${efi_num}" ]]
            then
	        mdadm --zero-superblock --force "${device}-part${efi_num}" >> $n
            fi

            if [[ -e "${device}-part${boot_num}" ]]
            then
	        mdadm --zero-superblock --force "${device}-part${boot_num}" >> $n
            fi

            if [[ -e "${device}-part${root_num}" ]]
            then
	        mdadm --zero-superblock --force "${device}-part${root_num}" >> $n
            fi

            if [[ -e "${device}-part${data_num}" ]]
            then
                mdadm --zero-superblock --force "${device}-part${data_num}" >> $n
            fi
        fi

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



	# Setup BIOS Partition
        end_bios=$((start_bios + bios_size))		# MiB

	echo "Creating BIOS partition on ${device}-part${bios_num}"

	parted --align=opt $device mkpart primary "${start_bios}MiB" "${end_bios}MiB" >> $n
	parted $device name 1 "${label}_BIOS" >> $n
	parted $device set 1 bios_grub on >> $n



        # Setup EFI Partition
        start_efi=$((end_bios))				# MiB
	end_efi=$((start_efi + efi_size))		# MiB

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
	start_boot=$((end_efi))				# MiB
	end_boot=$((start_boot + boot_size))		# MiB

	echo "Creating /boot partition on ${device}-part${bios_num}"
	parted --align=opt $device mkpart primary "${start_boot}MiB" "${end_boot}MiB" >> $n
	parted $device name 3 "${label}_BOOT" >> $n

        if [ "$bootfs" == "ext4" ]
        then
            # Set partition type
            sgdisk -t 8300 "${device}"

            # Wait a few seconds
            sleep 1

            # Filesystem will be created in another Script
            # mkfs.ext4  "${device}-part${boot_num}"
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




	# Setup / partition
	start_root=$((end_boot))			# MiB
	end_root=$((start_root + root_size))		# MiB

	echo "Creating / partition on ${device}-part${root_num}"
	parted --align=opt $device mkpart primary "${start_root}MiB" "${end_root}MiB" >> $n
	parted $device name 4 "${label}_ROOT" >> $n
	sgdisk -t 8309 "${device}"

	# Evaluate whether to encrypt /
        # Need to get the short disk name / device name
        disk="${disks[$counter]}"

        if [ "${encryptrootfs}" == "no" ]
        then
                echo "Skip Encryption Process for /"
        elif [ "${encryptrootfs}" == "luks" ]
        then
                # Ask for password
                # Initial values need to be intentionally different in order for the while loop to work correctly
                password="true"
                verify="false"
                while [ "$password" != "$verify" ]
                do
                      read -s -p "Enter encryption password for /: " password
                      echo ""
                      read -s -p "Verify encryption password for /: " verify

                      if [ "$password" != "$verify" ]
                      then
                             echo "Password Verification failed for / - Password do NOT match"
                      else
                             echo "Password Verification successful for /"
                      fi
                done

                echo $password | cryptsetup -q -v --type luks2 --cipher aes-xts-plain64 --hash sha512 --key-size 512 --use-random --iter-time 5000 luksFormat "${device}-part${root_num}"
                echo -n $password | cryptsetup open --type luks2 "${device}-part${root_num}" "${disk}_root_crypt"
                unset $password
                unset $verify

        else
                echo "Encryption mode <${encryptrootfs}> for / is NOT supported. Aborting !"
                exit 1
        fi

        # Wait a few seconds
        sleep 1





	# Setup /data partition
        if [[ "${data_separate}" == "yes" ]]
        then
	    start_data=$((end_root))				# MiB
	    end_data=$((start_data + data_size))		# MiB

	    echo "Creating / partition on ${device}-part${data_num}"
	    parted --align=opt $device mkpart primary "${start_data}MiB" "${end_data}MiB" >> $n
	    parted $device name 4 "${label}_DATA" >> $n
	    sgdisk -t 8309 "${device}"

	    # Evaluate whether to encrypt /data
            # Need to get the short disk name /data device name
            disk="${disks[$counter]}"

            if [ "${encryptdatafs}" == "no" ]
            then
                echo "Skip Encryption Process for /data"
            elif [ "${encryptdatafs}" == "luks" ]
            then
                # Ask for password
                # Initial values need to be intentionally different in order for the while loop to work correctly
                password="true"
                verify="false"
                while [ "$password" != "$verify" ]
                do
                      read -s -p "Enter encryption password for /data: " password
                      echo ""
                      read -s -p "Verify encryption password for /data: " verify

                      if [ "$password" != "$verify" ]
                      then
                             echo "Password Verification failed for /data - Password do NOT match"
                      else
                             echo "Password Verification successful for /data"
                      fi
                done

                echo $password | cryptsetup -q -v --type luks2 --cipher aes-xts-plain64 --hash sha512 --key-size 512 --use-random --iter-time 5000 luksFormat "${device}-part${data_num}"
                echo -n $password | cryptsetup open --type luks2 "${device}-part${data_num}" "${disk}_data_crypt"
                unset $password
                unset $verify
            else
                echo "Encryption mode <${encryptdatafs}> for /data is NOT supported. Aborting !"
                exit 1
            fi

            # Wait a few seconds
            sleep 1
        fi







        # End of the Current Disk processing

	# Increment counter
	counter=$((counter+1))

        # Move on to the next Disk
done

# Setup RAID mirror (RAID-1)
echo "=================================================================================================="
echo "====================================== SETUP RAID ================================================"
echo "=================================================================================================="

# Wait a bit
sleep 2

# Rescan Partitions
partprobe

# Wait a bit
sleep 5

# Setup EFI Partition / RAID1
source ${toolpath}/modules/setup_efi_partition.sh

# Setup /boot Partition / RAID1
source ${toolpath}/modules/setup_boot_partition.sh

# Setup / Partition / RAID1
source ${toolpath}/modules/setup_root_partition.sh

# Setup / Partition /data RAID1
if [[ "${separate_data}" == "yes" ]]
then
    source ${toolpath}/modules/setup_data_partition.sh
fi
