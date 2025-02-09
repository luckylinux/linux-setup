#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
source $toolpath/load.sh

# Load ZFS module
modprobe spl
modprobe zfs

# Export pool if in use
if [ "$rootfs" == "zfs" ]
then
    zpool export -f $rootpool
fi

# Close LUKS devices if applicable
# If root device is encrypted
if [ "$encryptrootfs" == "luks" ]
then
	# Close $device1
	cryptsetup luksClose ${disk1}_crypt

	if [ $numdisks -eq 2 ]
        then
		# Close $device2
		cryptsetup luksClose ${disk2}_crypt
	fi
fi

# Kill all running processes
killall parted

# Load mdadm if not running already
systemctl start mdadm

# Stop existing arrays if exists
# EFI
if [ -e "/dev/${mdadm_efi_device}" ]
then
	echo "Remove disks from /dev/${mdadm_efi_device}"
	mdadm --stop /dev/${mdadm_efi_device}

	sleep 2

	mdadm /dev/${mdadm_efi_device} --fail "${device1}-part${efi_num}"
	mdadm /dev/${mdadm_efi_device} --fail "${device2}-part${efi_num}"

	sleep 2

	mdadm /dev/${mdadm_efi_device} --remove "${device1}-part${efi_num}"
	mdadm /dev/${mdadm_efi_device} --remove "${device2}-part${efi_num}"

	echo "Stopping /dev/${mdadm_efi_device}"
	mdadm --stop /dev/${mdadm_efi_device}

        sleep 2
fi

# /boot
if [ -e "/dev/${mdadm_boot_device}" ]
then
	echo "Remove disks from /dev/${mdadm_boot_device}"
	mdadm --stop /dev/${mdadm_boot_device}

	sleep 2

	mdadm ${mdadm_boot_device} --fail "${device1}-part${boot_num}"
	mdadm ${mdadm_boot_device} --fail "${device2}-part${boot_num}"

	sleep 2

	mdadm ${mdadm_boot_device} --remove "${device1}-part${boot_num}"
	mdadm ${mdadm_boot_device} --remove "${device2}-part${boot_num}"

	echo "Stopping /dev/${mdadm_boot_device}"
	mdadm --stop /dev/${mdadm_boot_device}

        sleep 2
fi

# /
if [ -e "/dev/${mdadm_root_device}" ]
then
	echo "Remove disks from /dev/${mdadm_root_device}"
	mdadm --stop /dev/${mdadm_root_device}

	sleep 2

	mdadm ${mdadm_root_device} --fail "${device1}-part${root_num}"
	mdadm ${mdadm_root_device} --fail "${device2}-part${root_num}"

	sleep 2

	mdadm ${mdadm_root_device} --remove "${device1}-part${root_num}"
	mdadm ${mdadm_root_device} --remove "${device2}-part${root_num}"

	echo "Stopping /dev/${mdadm_root_device}"
	mdadm --stop /dev/${mdadm_root_device}

        sleep 2
fi
