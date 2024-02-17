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

# Kill all running processes
killall parted

# Load mdadm if not running already
systemctl start mdadm

# Stop existing arrays if exists

# EFI
if [ -e "/dev/${mdadm_efi_device}" ]; then
	echo "Remove disks from /dev/${mdadm_efi_device}"
	mdadm /dev/md127 --fail "${device1}-part2"
	mdadm /dev/md127 --fail "${device2}-part2"
	sleep 1
	mdadm /dev/md127 --remove "${device1}-part2"
	mdadm /dev/md127 --remove "${device2}-part2"

	echo "Stopping /dev/${mdadm_efi_device}"
	mdadm --stop /dev/${mdadm_efi_device}
        sleep 1
fi

# /boot
if [ -e "/dev/${mdadm_boot_device}" ]; then
	echo "Remove disks from /dev/${mdadm_boot_device}"
	mdadm /dev/md100 --fail "${device1}-part3"
	mdadm /dev/md100 --fail "${device2}-part3"
	sleep 1
	mdadm /dev/md100 --remove "${device1}-part3"
	mdadm /dev/md100 --remove "${device2}-part3"

	echo "Stopping /dev/${mdadm_boot_device}"
	mdadm --stop /dev/${mdadm_boot_device}
fi

# /
if [ -e "/dev/${mdadm_root_device}" ]; then
	echo "Remove disks from /dev/${mdadm_root_device}"
	mdadm /dev/md101 --fail "${device1}-part4"
	mdadm /dev/md101 --fail "${device2}-part4"
	sleep 1
	mdadm /dev/md101 --remove "${device1}-part4"
	mdadm /dev/md101 --remove "${device2}-part4"

	echo "Stopping /dev/${mdadm_root_device}"
	mdadm --stop /dev/${mdadm_root_device}
fi
