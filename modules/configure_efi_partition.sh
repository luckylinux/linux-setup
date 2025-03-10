#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source $toolpath/load.sh

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

# Ensure that /boot/efi can be written directly
chattr -i /boot/efi


echo "# EFI/ESP Devices" >> /etc/fstab
for disk in "${disks[@]}"
do
     # Create Folder
     mkdir -p "/boot/efi/${disk}"

     # Ensure that nothing is mounted there
     if mountpoint -q "/boot/efi/${disk}"
     then
	umount "/boot/efi/${disk}"
     fi

     # Ensure that /boot/efi/<disk> CANNOT be written directly (a partition must be mounted there)
     chattr +i "/boot/efi/${disk}"

     # Configure FSTAB
     UUID=$(blkid -s UUID -o value /dev/disk/by-id/${disk}-${efi_num})

     echo "UUID=$UUID           /boot/efi/${disk}		vfat		nofail,x-systemd.automount,umask=0022,fmask=0022,dmask=0022		0	1" >> /etc/fstab
done


# Configure FSTAB
#        if [ "${numdisks_total}" -eq 2 ]
#        then
#                # Install mdadm if not already installed
#                if [[ -z $(command -v mdadm) ]]
#                then
#                    apt-get install -y mdadm
#                fi
#
#                # Configure MDADM Array in /etc/fstab
#                UUID=$(blkid -s UUID -o value /dev/${mdadm_efi_device})
#                echo "# /boot/efi on vfat with MDADM Software Raid-1" >> /etc/fstab
#                echo "UUID=$UUID	/boot/efi		vfat		nofail,x-systemd.automount,umask=0022,fmask=0022,dmask=0022		0	1" >> /etc/fstab
#
#		# Also add MDADM Array to /etc/mdadm/mdadm.conf
#                # When this is enabled, mdadm does NOT create the devices as expected
#                # The boot process might also be interrupted, dropping you to an emergency shell
#		#mdadm --detail --scan | grep "/dev/${mdadm_efi_device}" >> /etc/mdadm/mdadm.conf
#
#                # Alternative is to use a custom Systemd service together with a custom made automount mdadm-assemble.service
#                # The installation is handle by modules/setup_systemd_mdadm_assemble.sh
#                tee /etc/mdadm/efi.mdadm << EOF
##!/bin/bash
#
## Load Global Configuration
##source /etc/mdadm/global.sh
#
## Define mdadm Device
#mdadm_device="/dev/${mdadm_efi_device}"
#
## List Member Devices
#member_devices=()
#member_devices+=( "${devices[0]}-part${efi_num}" )
#member_devices+=( "${devices[1]}-part${efi_num}" )
#EOF
#
#                # Install tool
#                source $toolpath/modules/setup_systemd_mdadm_assemble.sh
#
#        elif [ "${numdisks_total}" -eq 1 ]
#        then
#                # Configure Partition in /etc/fstab
#                UUID=$(blkid -s UUID -o value ${devices[0]}-part${efi_num})
#		echo "# /boot/efi on vfat" >> /etc/fstab
#                echo "UUID=$UUID	/boot/efi		vfat		nofail,x-systemd.automount,umask=0022,fmask=0022,dmask=0022		0	1" >> /etc/fstab
#        else
#                echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
#                exit 1
#        fi

# Reload Systemd as applicable due to changed /etc/fstab
systemctl daemon-reload

# Mount EFI partition
for disk in "${disks[@]}"
do
    mount "/boot/efi/${disk}"
done
