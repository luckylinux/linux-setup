#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Umount previosuly mounted pools & filesystems
source $toolpath/modules/umount_bind.sh

if [ "$rootfs" == "zfs" ]
then
    zfs umount $rootpool
    zfs umount $rootpool/ROOT/$distribution
    zfs umount -a
    zpool export -f $rootpool
fi

if [ "$bootfs" == "zfs" ]
then
    zfs umount $bootpool
    zfs umount $bootpool/BOOT/$distribution
    zfs umount -a
    zpool export -f $bootpool
fi

echo -e "\nWARNING: In case of errors it might be easier to just REBOOT the system\n"
sleep 5

# Init partitioning
source $toolpath/modules/init_partitioning.sh

# Setup disks
source $toolpath/modules/setup_partitions.sh

# Setup datasets
source $toolpath/modules/setup_datasets.sh

# Setup minimal system
source $toolpath/modules/setup_minimal.sh
