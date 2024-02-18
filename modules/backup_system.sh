#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

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
