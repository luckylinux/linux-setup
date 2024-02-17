#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load Configuration
source $toolpath/config.sh

# Ensure that /boot is mounted
if mountpoint -q "/boot"
then
        echo "/boot is already mounted"
else
	mount /boot
fi

# Check if /boot/efi exists
if [ ! -d /boot/efi ]
then
        # If /boot/efi does NOT exist, then create folder
	mkdir -p /boot/efi
else
	# Ensure that nothing is mounted there
        if mountpoint -q "/boot/efi"
	then
		umount /boot/efi
	fi
fi

# Ensure that /boot/efi cannot be written directly (a partition must be mounted there)
chattr +i /boot/efi

# Configure FSTAB
        if [ "$numdisks" -eq 2 ]
        then
                # Configure MDADM Array in /etc/fstab
                UUID=$(blkid -s UUID -o value /dev/${mdadm_boot_device})
                echo "# /boot/efi on vfat with MDADM Software Raid-1" >> /etc/fstab
                echo "UUID=$UUID	/boot/efi	vfat	umask=0022,fmask=0022,dmask=0022	0       1" >> /etc/fstab

        elif [ "$numdisks" -eq 1 ]
        then
                # Configure Partition in /etc/fstab
                UUID=$(blkid -s UUID -o value $device1-part${efi_num})
		echo "# /boot/efi on vfat" >> /etc/fstab
                echo "UUID=$UUID        /boot/efi       vfat    umask=0022,fmask=0022,dmask=0022        0       1" >> /etc/fstab
        else
                echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
                exit 1
        fi

# Reload Systemd as applicable due to changed /etc/fstab
systemctl daemon-reload

# Mount EFI partition
mount /boot/efi
