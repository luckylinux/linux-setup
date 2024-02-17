#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Setup required tools
#source $toolpath/modules/setup_requirements.sh

# Backup existing pool
#source $toolpath/modules/backup_system.sh

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
