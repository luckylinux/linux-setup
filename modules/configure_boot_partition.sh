#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load Configuration
source $toolpath/config.sh

# Configure FSTAB
if [ "$bootfs" == "zfs" ]
then
    echo "Skipping Configuration of FSTAB due to ZFS automount generator"
elif [ "$bootfs" == "ext4" ]
then
        if [ "$numdisks" -eq 2 ]
        then
                # Configure MDADM Array in /etc/fstab
                UUID=$(blkid -s UUID -o value /dev/${mdadm_boot_device})
                echo "# /boot on ext4 with MDADM Software Raid-1" >> /etc/fstab
                echo "UUID=$UUID	/boot	ext4            auto,nofail,x-systemd.automount            0      1" >> /etc/fstab

		# Also add MDADM Array to /etc/mdadm/mdadm.conf
                # When this is enabled, mdadm does NOT create the devices as expected
                # The boot process might also be interrupted, dropping you to an emergency shell
		#mdadm --detail --scan | grep "/dev/${mdadm_boot_device}" >> /etc/mdadm/mdadm.conf
        elif [ "$numdisks" -eq 1 ]
        then
                # Configure Partition in /etc/fstab
                UUID=$(blkid -s UUID -o value $device1-part${boot_num})
		echo "# /boot on ext4" >> /etc/fstab
                echo "UUID=$UUID        /boot   ext4            auto,nofail,x-systemd.automount            0      1" >> /etc/fstab
        else
                echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
                exit 1
        fi
else
        echo "Only ZFS and EXT4 are currently supported. Aborting !"
        exit 1
fi

# Reload Systemd as applicable due to changed /etc/fstab
systemctl daemon-reload
