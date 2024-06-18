#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Import ZFS pool if not already mounted
if [ "$rootfs" == "zfs" ]
then
        zpool import -f $rootpool -R "${destination}"
        zfs mount $rootpool/ROOT/$distribution
        zfs set devices=off $rootpool

        # Get list of datasets
        datasets=$(zfs list -H -o name | grep -i "$rootpool" | xargs -n1)

        while IFS= read -r dataset; do
            zfs mount $dataset
        done <<< "$datasets"
fi

# Import ZFS pool if not already mounted
if [ "$bootfs" == "zfs" ]
then
        zpool import -f $bootpool -R "${destination}"
        zfs mount $bootpool/BOOT/$distribution

        # Get list of datasets
        datasets=$(zfs list -H -o name | grep -i "$bootpool" | xargs -n1)

        while IFS= read -r dataset; do
            zfs mount $dataset
        done <<< "$datasets"
fi
