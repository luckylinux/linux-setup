#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Umount previosuly mounted bind mounts
source $toolpath/modules/umount_bind.sh

# Umount previosuly mounted Chroot
source $toolpath/modules/umount_chroot.sh

# Umount previosuly mounted ZFS Pools
source $toolpath/modules/umount_zfs.sh

# Umount everything that remains by force
source $toolpath/modules/umount_force_all.sh
