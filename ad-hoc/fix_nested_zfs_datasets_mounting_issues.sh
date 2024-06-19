#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Load Functions
source $toolpath/functions.sh

# Unmount everything by default
zfs umount -a

# Mount just the root dataset
zfs mount $rootpool/ROOT/$distribution

# Get list of datasets
datasets=$(zfs list -H -o name | grep -i "$rootpool" | xargs -n1)

# Loop over Datasets
while IFS= read -r dataset
do
    # Get mountpoint
    mountpt=$(zfs get -H mountpoint -o value)
    echo $mountp


    # Check if Mountpoint is empty or not
    if test -n "$(find ./ -maxdepth 0 -empty)"
    then
        echo "Test"
    fi

    # If it's a dataset, NOT a zvol
#	    if [ ! -b /dev/zvol/$dataset ]
#            then
#                zfs set canmount=on $dataset
#            fi


done <<< "$datasets"

