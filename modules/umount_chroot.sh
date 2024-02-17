#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load config
source $toolpath/config.sh

# Disable swap
swapoff -a

# Umount proc, sys, dev
source $toolpath/modules/umount_bind.sh

# Umount root/boot
if mountpoint -q "${destination}/boot"
then
	umount -R "${destination}/boot"
fi

if mountpoint -q "${destination}"
then
	umount -R "${destination}"
fi

# Export pool
if [ "$rootfs" == "zfs" ]
then
    zpool export -f $rootpool
fi

if [ "$bootfs" == "zfs" ]
then
    zpool export -f $bootpool
fi
