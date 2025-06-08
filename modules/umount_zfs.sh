#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# If either Root Filesystem and/or Boot Filesystem is on ZFS
if [ "${rootfs}" == "zfs" ] || [ "${bootfs}" == "zfs" ]
then
    if [[ $(command -v zfs) ]]
    then
        zfs umount -a
    fi
fi

# Unmount ZFS Root Pool
if [ "${rootfs}" == "zfs" ]
then
    if [[ $(command -v zfs) ]]
    then
        zfs umount ${rootpool}
        zfs umount ${rootpool}/ROOT/${distribution}
    fi

    if [[ $(command -v zpool) ]]
    then
        # Export Pool
        zpool export -f ${rootpool}
    fi
fi

# Unmount ZFS Boot Pool
if [ "${bootfs}" == "zfs" ]
then
    if [[ $(command -v zfs) ]]
    then
        zfs umount ${bootpool}
        zfs umount ${bootpool}/BOOT/${distribution}
    fi

    if [[ $(command -v zpool) ]]
    then
        # Export Pool
        zpool export -f ${bootpool}
    fi
fi

# If either Root Filesystem and/or Boot Filesystem is on ZFS
# Try to unmount everything again
if [ "${rootfs}" == "zfs" ] || [ "${bootfs}" == "zfs" ]
then
    if [[ $(command -v zfs) ]]
    then
        zfs umount -a
    fi
fi
