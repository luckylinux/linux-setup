#!/bin/bash

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ] 
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source "${toolpath}/load.sh"

# Mount /boot if not already mounted
if mountpoint -q "/boot"
then
	x=1	# Silent
else
	mount /boot
fi


for disk in "${disks[@]}"
do
	# Get EFI Mount Path
	efi_mount_path=$(get_efi_mount_path "${disk}")

	# Mount /boot/efi/<disk> if not already mounted
	if mountpoint -q "${efi_mount_path}"
	then
		x=1 # Silent
	else
		mount "${efi_mount_path}"
	fi
done

# Update initramfs
regenerate_initrd

if [ "${bootloader}" == "grub" ]
then
	# Install both Packages in the Case of Fedora, since they don't conflict with one another
	if [[ "${DISTRIBUTION_FAMILY}" == "fedora" ]]
	then
		# Install GRUB Tools
		install_packages_unattended grub2-pc-modules

		# Install GRUB for BIOS
		install_packages_unattended grub2-pc grub2-pc-modules

		# Install GRUB for UEFI
		install_packages_unattended grub2-efi-x64 grub2-efi-x64-modules shim-x64
	fi

	# Install GRUB to MBR
	if [[ "${bootloadermode}" == "BIOS" ]]
	then
		if [[ "${DISTRIBUTION_FAMILY}" == "debian" ]]
		then
			# Install GRUB for BIOS (Primary)
			install_packages_unattended grub-pc

			# Install GRUB for UEFI (Secondary)
			install_packages_unattended grub-efi-amd64-bin shim-signed
		fi

	    # BIOS
	    for disk in "${disks[@]}"
	    do
	        grub_install "/dev/disk/by-id/${disk}"
        done
	elif [[ "${bootloadermode}" == "UEFI" ]]
            then
            # Might be intesting to also rename UEFI Labels/Entries
            # See for instance https://askubuntu.com/questions/1125920/how-can-i-change-the-names-of-items-in-the-efi-uefi-boot-menu

            # Install GRUB and Shim for UEFI (Primary)
            install_packages_unattended grub-efi-amd64 shim-signed

            # Attempt to install SHIM Helpers (Debian only, NOT Ubuntu)
			if [[ "${DISTRIBUTION_RELEASE}" == "debian" ]]
			then
            	install_packages_unattended shim-helpers-amd64-signed
			fi

            # Install GRUB for BIOS (Secondary)
            install_packages_unattended grub-pc-bin
	else
	    # Not Supported
	    echo "Error - bootloadermode <${bootloadermode}> is NOT supported. Aborting"
	    exit 1
	fi

	# Copy files to /etc/grub.d to be sure that the correct root=ZFS=${rootpool}/ROOT/$distribution is generated
	# (otherwise sometimes root=ZFS=/ROOT/$distribution is used instead which of course fails, returning you to busybox without any error/message)
	# See issue https://github.com/zfsonlinux/grub/issues/18

	# Choose file source
	#if [ "$distribution" == "debian" ]
	#then
	#	dir="$toolpath/files/grub/ubuntu/2.06-2"
	#elif [ "$distribution" == "ubuntu" ]
	#then
	#	dir="$toolpath/files/grub/ubuntu/2.12-rc1"
	#else
	#	dir="$toolpath/files/grub/debian/2.06-2"
	#	echo "Distribution <$distribution> not implemented yet. Continuing with GRUB installation using Debian GRUB2 scripts ..."
	#fi

	#for f in $dir/*
	#do
	#	# Get only filename without path
	#	name=$(basename $f)
	#
	#	# Copy to /etc/grub.d
	#	cp $f /etc/grub.d/
	#
	#	# Make it executable
	#	chmod +x /etc/grub.d/$name
	#done

        # Install **BOTH** BIOS Bootloader **AND** UEFI Bootloader

        # BIOS
        for disk in "${disks[@]}"
	    do
	        grub_install "/dev/disk/by-id/${disk}"
        done
		# UEFI
		for disk in "${disks[@]}"
		do
			# Get EFI Mount Path
			efi_mount_path=$(get_efi_mount_path "${disk}")

			# grub_install --target=x86_64-efi "/dev/disk/by-id/${disk}"
			# grub_install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck --no-floppy
			grub_install --target=x86_64-efi --efi-directory="${efi_mount_path}" --boot-directory="/boot/" --no-nvram "/dev/disk/by-id/${disk}"
		done

        # Make sure to set the correct UUID for Kernel Command Line
        sed -Ei "s|(.*?)root=UUID=([a-f0-9-]+)\s(.*?)|\1root=UUID=\2 \3|" /etc/kernel/cmdline

        # Fedora: Remove all Files in /boot/loader/entries/*.conf, then reinstall kernel-core to Trigger GRUB update to use new Partition Layout
        force_grub_configuration_update_after_partition_changes

	# Disable some GRUB modules
	chmod -x /etc/grub.d/30_os-prober

	# Update GRUB configuration
    update_grub_configuration

	# Update GRUB once again
	update_grub_configuration

	# Check which filesystem is on /boot
	grub_probe /boot

elif [ "${bootloader}" == "zbm" ]
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
regenerate_initrd

# Update GRUB once again
update_grub_configuration
