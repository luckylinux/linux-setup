#!/bin/bash

# Do NOT Abort on errors
#set -e

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Get list of datasets
datasets=$(zfs list -H -o name | grep -i "rpool/data" | xargs -n1)

while IFS= read -r dataset; do
    # Mount it
    echo "Enable dataset ${dataset}"
    zfs set canmount=on ${dataset}
    zfs set mountpoint=/${dataset} ${dataset}
    zfs set readonly=off ${dataset}
done <<< "${dataset}s"

# Some Manual Operations are required
zfs set canmount=off ${rootpool}
zfs set canmount=off ${rootpool}/ROOT
zfs set canmount=noauto ${rootpool}/ROOT/debian

# Set Swap as read-write
zfs set readonly=off ${rootpool}/swap

# Data must not mount by default
# Mainly used for ZVOLs anyways
zfs set mountpoint=/${rootpool}/data ${rootpool}/data
#zfs set canmount=off ${rootpool}/data <--- This is the original configuration
zfs set canmount=on ${rootpool}/data
zfs inherit -r mountpoint ${rootpool}/data

# LXC Containers MUST be allowed to mount
for item in /${rootpool}/data/subvol*
do
   zfs set canmount=on ${item/"/"/""}
done

