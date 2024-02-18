#!/bin/bash

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ] 
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load Configuration
source $toolpath/config.sh

# Update initramfs
update-initramfs -k all -u

if [ "$bootloader" == "grub" ]
then
	# Install GRUB to MBR
	if [ "$bootloadermode" == "BIOS" ]
	then
	    # Install GRUB
	    apt-get install --yes grub-pc

	    # BIOS
	    grub-install "${device1}"

            if [ "$numdisks" -eq 2 ]
            then
	         grub-install "${device2}"
            fi
	elif [ "$bootloadermode" == "UEFI" ]
	then
	    # Install GRUB
	    apt-get install --yes grub-efi-amd64

	    # UEFI
	    grub-install --target=x86_64-efi "${device1}"

	    if [ "$numdisks" -eq 2 ]
            then
		grub-install --target=x86_64-efi "${device2}"
	    fi

	    #grub-install --target=x86_64-efi --efi-directory=/boot/efi \
	    #--bootloader-id=ubuntu --recheck --no-floppy
	else
	    # Not Supported
	    echo "Error - bootloadermode <${bootloadermode}> is NOT supported. Aborting"
	    exit 1
	fi

	# Update GRUB configuration
	update-grub

	# Update GRUB once again
	update-grub

	# Check which filesystem is on /boot
	grub-probe /boot

elif [ "$bootloader" == "zbm" ]
then
	# Useful notes
	# LUKS: https://github.com/zbm-dev/zfsbootmenu/blob/master/contrib/luks-unlock.sh
	# Clevis: https://github.com/zbm-dev/zfsbootmenu/discussions/441

	echo "Bootloader <zbm> not implemented yet. Aborting !"
	exit 2
else
	echo "Bootloader <$bootloader> not supported. Aborting !"
	exit 1
fi

