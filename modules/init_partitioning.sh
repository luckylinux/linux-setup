#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load config
source $toolpath/config.sh

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
if [ -e "/dev/${mdadm_efi_device}" ]; then
	echo "Remove disks from /dev/${mdadm_efi_device}"
	mdadm /dev/${mdadm_efi_device} --fail "${device1}-part2"
	mdadm /dev/${mdadm_efi_device} --fail "${device2}-part2"
	sleep 1
	mdadm /dev/${mdadm_efi_device} --remove "${device1}-part2"
	mdadm /dev/${mdadm_efi_device} --remove "${device2}-part2"

	echo "Stopping /dev/${mdadm_efi_device}"
	mdadm --stop /dev/${mdadm_efi_device}
        sleep 1
fi

# /boot
if [ -e "/dev/${mdadm_boot_device}" ]; then
	echo "Remove disks from /dev/${mdadm_boot_device}"
	mdadm ${mdadm_boot_device} --fail "${device1}-part3"
	mdadm ${mdadm_boot_device} --fail "${device2}-part3"
	sleep 1
	mdadm ${mdadm_boot_device} --remove "${device1}-part3"
	mdadm ${mdadm_boot_device} --remove "${device2}-part3"

	echo "Stopping /dev/${mdadm_boot_device}"
	mdadm --stop /dev/${mdadm_boot_device}
        sleep 1
fi

# /
if [ -e "/dev/${mdadm_root_device}" ]; then
	echo "Remove disks from /dev/${mdadm_root_device}"
	mdadm ${mdadm_root_device} --fail "${device1}-part4"
	mdadm ${mdadm_root_device} --fail "${device2}-part4"
	sleep 1
	mdadm ${mdadm_root_device} --remove "${device1}-part4"
	mdadm ${mdadm_root_device} --remove "${device2}-part4"

	echo "Stopping /dev/${mdadm_root_device}"
	mdadm --stop /dev/${mdadm_root_device}
        sleep 1
fi
