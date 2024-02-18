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

# Mount /boot if not already mounted
if mountpoint -q "/boot"
then
	x=1	# Silent
else
	mount /boot
fi

# Mount /boot/efi if not already mounted
if mountpoint -q "/boot/efi"
then
	x=1	# Silent
else
	mount /boot/efi
fi

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

	# Copy files to /etc/grub.d to be sure that the correct root=ZFS=$rootpool/ROOT/$distribution is generated
	# (otherwise sometimes root=ZFS=/ROOT/$distribution is used instead which of course fails, returning you to busybox without any error/message)
	# See issue https://github.com/zfsonlinux/grub/issues/18

	# Choose file source
	if [ "$distribution" == "debian" ]
	then
		dir="$toolpath/files/grub/ubuntu/2.06-2"
	elif [ "$distribution" == "ubuntu" ]
	then
		dir="$toolpath/files/grub/ubuntu/2.12-rc1"
	else
		dir="$toolpath/files/grub/debian/2.06-2"
		echo "Distribution <$distribution> not implemented yet. Continuing with GRUB installation using Debian GRUB2 scripts ..."
	fi

	for f in $dir/*
	do
		# Get only filename without path
		name=$(basename $f)

		# Copy to /etc/grub.d
		cp $f /etc/grub.d/

		# Make it executable
		chmod +x /etc/grub.d/$name
	done

	# Disable some GRUB modules
	chmod -x /etc/grub.d/30_os-prober

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

# Update initramfs once again
update-initramfs -k all -u

# Update GRUB once again
update-grub
