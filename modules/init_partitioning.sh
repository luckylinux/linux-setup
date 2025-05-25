#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
source "${toolpath}/load.sh"

# Load ZFS module
modprobe spl
modprobe zfs

# Export pool if in use
if [ "${rootfs}" == "zfs" ]
then
    zpool export -f ${rootpool}
fi

# Close LUKS devices if applicable
# If root device is encrypted
if [ "${encryptrootfs}" == "luks" ]
then
    for disk in "${disks[@]}"
    do
	    # Close Device
        if [[ -e "/dev/mapper/${disk}_root_crypt" ]]
        then
            cryptsetup luksClose "${disk}_root_crypt"
        fi
	done
fi

# Kill all running processes
killall parted

# Load mdadm if not running already
systemctl start mdadm

# Stop existing arrays if exists
source ${toolpath}/modules/umount_mdadm.sh
