#!/bin/bash

# Load configuration
source config.sh

# Load modules
modprobe spl
modprobe zfs

# Wait a few seconds
sleep 5

# Restore ZFS Snapshot
#ssh root@$backupserver zfs send -Rv $backupdataset@$snapshotname | zfs receive -Fduv $rootpool
ssh root@$backupserver zfs send -Rv $backupdataset@$snapshotname | zfs receive -F $rootpool

# Move /boot files to dedicated BOOT pool
zfs umount $bootpool/BOOT/$distribution
zfs mount $rootpool/ROOT/$distribution
mv $destination/boot $destination/boot_old
zfs mount $bootpool/BOOT/$distribution
cp -r $destination/boot_old/* destination/boot/
sync