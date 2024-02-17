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
                echo "UUID=$UUID	/boot	ext4            auto            0      1" >> /etc/fstab

        elif [ "$numdisks" -eq 1 ]
        then
                # Configure Partition in /etc/fstab
                UUID=$(blkid -s UUID -o value $device1-part3)
		echo "# /boot on ext4" >> /etc/fstab
                echo "UUID=$UUID        /boot   ext4            auto            0      1" >> /etc/fstab
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
