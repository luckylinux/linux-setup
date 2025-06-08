#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Install rsync
apt-get install rsync

# Check to See if restore_from_mountpoint is set and exists
if [ -z "${restore_from_mountpoint}" ] || [ ! -d "${restore_from_mountpoint}" ]
then
    # Ask User Input
    read -p "Enter the Mountpoint where the System to Migrate is currently Mounted: " restore_from_mountpoint
fi

# Check that it's mounted
if mountpoint -q "${restore_from_mountpoint}"
then
    # Check if /boot
    if ! mountpoint -q "${restore_from_mountpoint}/boot"
    then
        read -p "WARNING: ${restore_from_mountpoint}/boot does NOT contain a mounted Filesystem. Continue ? [yes/no]: "  keep_going

        if [[ "${keep_going}" != "yes" ]]
        then
           exit 8
        fi
    fi

    # Check if /boot/efi are mounted
    if ! mountpoint -q "${restore_from_mountpoint}/boot/efi"
    then
        read -p "WARNING: ${restore_from_mountpoint}/boot/efi does NOT contain a mounted Filesystem. Continue ? [yes/no]: "  keep_going

        if [[ "${keep_going}" != "yes" ]]
        then
           exit 8
        fi
    fi

    # Copy Data using rsync
    rsync -aPAXUHEtv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} ${restore_from_mountpoint}/ ${destination}
else
    # Abort
    echo "ERROR: Path ${restore_from_mountpoint} does NOT contain a mounted Filesystem. Aborting !"
    exit 9
fi
