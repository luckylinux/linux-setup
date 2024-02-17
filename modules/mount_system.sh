#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Import ZFS pool if not already mounted
if [ "$rootfs" == "zfs" ]
then
        zpool import $rootpool -R "${destination}"
        zfs mount $rootpool/ROOT/$distribution
        zfs set devices=off $rootpool
fi

# Import ZFS pool if not already mounted
if [ "$bootfs" == "zfs" ]
then
        zpool import $bootpool -R "${destination}"
        zfs mount $bootpool/BOOT/$distribution
fi
