#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# (Re)Set mountpoints for ZFS pools
if [ "$rootfs" == "zfs" ]
then
        # Get list of datasets
        datasets=$(zfs list -H -o name | grep -i "$rootpool" | xargs -n1)

        while IFS= read -r dataset; do
            # Enable dataset
#	    if [ ! -b /dev/zvol/$dataset ]
#            then
                zfs set canmount=on $dataset
#            fi

            zfs set readonly=inherited $dataset
        done <<< "$datasets"

        # Set properties for the main dataset
        zfs set mountpoint=/ $rootpool
        zfs set canmount=off $rootpool
        zfs set readonly=off $rootpool

        zfs set mountpoint=none $rootpool/ROOT
        zfs set canmount=off $rootpool/ROOT
        zfs set readonly=off $rootpool/ROOT

        zfs set mountpoint=/ $rootpool/ROOT/$distribution
        zfs set canmount=noauto $rootpool/ROOT/$distribution
        zfs set readonly=off $rootpool/ROOT/$distribution
fi

# (Re)Set mountpoints for ZFS pools
if [ "$bootfs" == "zfs" ]
then
        # Get list of datasets
        datasets=$(zfs list -H -o name | grep -i "$bootpool" | xargs -n1)

        while IFS= read -r dataset; do
            # Enable dataset
#            if [ ! -b /dev/zvol/$dataset ]
#            then
                zfs set canmount=on $dataset
#            fi

            zfs set readonly=inherited $dataset
        done <<< "$datasets"

        # Set properties for the main dataset
        zfs set mountpoint=/ $bootpool
        zfs set canmount=off $bootpool
        zfs set readonly=off $bootpool

        zfs set mountpoint=none $bootpool/BOOT
        zfs set canmount=off $bootpool/BOOT
        zfs set readonly=off $bootpool/BOOT

        zfs set mountpoint=/ $bootpool/BOOT/$distribution
        zfs set canmount=noauto $bootpool/BOOT/$distribution
        zfs set readonly=off $bootpool/BOOT/$distribution
fi

