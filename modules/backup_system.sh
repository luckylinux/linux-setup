#!/bin/bash

# Load configuration
source ../config.sh

# Load modules
modprobe spl
modprobe zfs

# Import existing pool
mkdir -p $destination
chattr +i $destination
zpool import -R $destination -f $rootpool

# Wait a few seconds
sleep 5

# Snapshot all
zfs snapshot -r $rootpool@$snapshotname

# Send to remote server
#zfs send -Rv $rootpool@snapshotname | ssh root@backupserver zfs receive -F $backupdataset
zfs send -Rv $rootpool@$snapshotname | ssh root@$backupserver zfs receive -Fduv $backupdataset