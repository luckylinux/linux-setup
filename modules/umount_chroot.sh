#!/bin/bash

# Load config
source ../config.sh

# Disable swap
swapoff -a

# Umount proc, sys, dev
bash umount_bind.sh

# Umount root/boot
umount -R "${destination}/boot"
umount -R "${destination}"

# Export pool
if [ "$rootfs" == "zfs" ]
then
    zpool export -f $rootpool
fi

if [ "$bootfs" == "zfs" ]
then
    zpool export -f $bootpool
fi
