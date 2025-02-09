#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/load.sh

# Load modules
modprobe spl
modprobe zfs

# Wait a few seconds
sleep 5

# Restore ZFS Snapshot
#ssh root@$backupserver zfs send -Rv $backupdataset@$snapshotname | zfs receive -Fduv $rootpool
ssh root@$backupserver zfs send -Rv $backupdataset@$snapshotname | zfs receive -F $rootpool

# Restore ZFS mountpoints
source $toolpath/ad-hoc/restore_zfs_mountpoints.sh

# Move /boot files to dedicated BOOT pool
#zfs umount $bootpool/BOOT/$distribution
#zfs mount $rootpool/ROOT/$distribution
#mv $destination/boot $destination/boot_old
#zfs mount $bootpool/BOOT/$distribution
#cp -r $destination/boot_old/* destination/boot/
#sync
