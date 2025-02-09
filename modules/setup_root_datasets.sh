#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/load.sh

# Create dataset to act as container
zfs create -o canmount=off -o mountpoint=none ${rootpool}/ROOT

# Create / dataset
zfs create -o canmount=noauto -o mountpoint=/ ${rootpool}/ROOT/${distribution}
zfs mount ${rootpool}/ROOT/${distribution}
zpool set bootfs=${rootpool}/ROOT/${distribution} rpool

# Create data dataset
zfs create -o canmount=off -o mountpoint=none ${rootpool}/data
