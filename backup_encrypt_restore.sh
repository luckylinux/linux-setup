#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Setup Requirements for the Installation (Packages will be installed on the currently running HOST)
installroot="" # Needed to ensure that we install on the Host
source $toolpath/modules/setup_requirements.sh

# Backup existing pool
source $toolpath/modules/backup_system.sh

# Umount previosuly mounted pools & filesystems
source $toolpath/modules/umount_bind.sh
zfs umount -a

if [ "$bootfs" == "zfs" ]
then
    zfs umount $bootpool
    zpool export -f $bootpool
fi

if [ "$rootfs" == "zfs" ]
then
    zfs umount $rootpool
    zfs umount $rootpool/ROOT/$distribution
    zpool export -f $rootpool
    echo "\nWARNING: In case of errors it might be easier to just REBOOT the system\n"
    sleep 5
fi

# Init partitioning
source $toolpath/modules/init_partitioning.sh

# Setup disks
source $toolpath/modules/setup_partitions.sh

# Restore system
source $toolpath/modules/restore_system.sh

# Mount system
source $toolpath/modules/mount_system.sh

# Mount bind
source $toolpath/modules/mount_bind.sh

# Setup chroot
source $toolpath/modules/setup_chroot.sh
