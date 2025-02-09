#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
source $toolpath/load.sh

# Disable swap
swapoff -a

# Umount proc, sys, dev
source $toolpath/modules/umount_bind.sh

# Umount root/boot
if mountpoint -q "${destination}/boot/efi"
then
	umount -R "${destination}/boot/efi"
fi

if mountpoint -q "${destination}/boot"
then
	umount -R "${destination}/boot"
fi

if mountpoint -q "${destination}"
then
	umount -R "${destination}"
fi

# Try to unmount all ZFS filesystems first
zfs umount -a

# Kill all processes that keep $rootpool busy
# grep -i rpool /proc/*/mounts shows additional PID that are NOT shown by `mount -l`
mapfile processes < <(grep -i $rootpool /proc/*/mounts)
# Output might be something like
#/proc/1539/mounts:rpool/ROOT/debian /mnt/rescue zfs rw,nodev,noatime,xattr,noacl,casesensitive 0 0
#/proc/1555/mounts:rpool/ROOT/debian /mnt/rescue zfs rw,nodev,noatime,xattr,noacl,casesensitive 0 0
#/proc/1694/mounts:rpool/ROOT/debian /mnt/rescue zfs rw,nodev,noatime,xattr,noacl,casesensitive 0 0
#/proc/2617/mounts:rpool/ROOT/debian /mnt/rescue zfs rw,nodev,noatime,xattr,noacl,casesensitive 0 0
#/proc/450/mounts:rpool/ROOT/debian /mnt/rescue zfs rw,nodev,noatime,xattr,noacl,casesensitive 0 0
for line in "${processes[@]}"
do
	pid=$(echo $line | sed -En "s/\/proc\/([0-9]*)\/.*/\1/p")
	kill -9 $pid
done

# Export pool
if [ "$rootfs" == "zfs" ]
then
    zfs umount -a
    zpool export -f $rootpool
fi

if [ "$bootfs" == "zfs" ]
then
    zfs umount -a
    zpool export -f $bootpool
fi

# This causes `lsof` to look MUCH Deeper for opened Files and Processes
# User-Readable Information
# lsof -w -x l -x f +D "${destination}"

# Machine-Processable Information
# PID (p) = Process ID
# COMMAND (c) = Process Name
# NAME (n) = File NAME / PATH
#mapfile processes < <( lsof -f p,c,n -w -x l -x f +D "${destination}")
mapfile processes < <( lsof -w +D "${destination}" -x l -x f | tail -n +2 | awk '{ print $2 }' | uniq)
for process in "${processes[@]}"
do
        pid=process
        kill -9 $pid
done
