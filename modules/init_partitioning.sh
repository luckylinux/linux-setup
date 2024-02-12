#!/bin/bash

# Load config
source config.sh

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
/etc/init.d/mdadm start

# Stop existing arrays if exists
if [ -e "/dev/md127" ]; then
	echo "Remove disks from /dev/md127"
	mdadm /dev/md127 --fail "${device1}-part3"
	mdadm /dev/md127 --fail "${device2}-part3"
	sleep 1
	mdadm /dev/md127 --remove "${device1}-part3"
	mdadm /dev/md127 --remove "${device2}-part3"

	echo "Stopping /dev/md127"
	mdadm --stop /dev/md127
fi

if [ -e "/dev/md100" ]; then
	echo "Remove disks from /dev/md100"
	mdadm /dev/md100 --fail "${device1}-part2"
	mdadm /dev/md100 --fail "${device2}-part2"
	sleep 1
	mdadm /dev/md100 --remove "${device1}-part2"
	mdadm /dev/md100 --remove "${device2}-part2"

	echo "Stopping /dev/md100"
	mdadm --stop /dev/md100
fi

if [ -e "/dev/md101" ]; then
	echo "Remove disks from /dev/md101"
	mdadm /dev/md101 --fail "${device1}-part3"
	mdadm /dev/md101 --fail "${device2}-part3"
	sleep 1
	mdadm /dev/md101 --remove "${device1}-part3"
	mdadm /dev/md101 --remove "${device2}-part3"

	echo "Stopping /dev/md101"
	mdadm --stop /dev/md101
fi
