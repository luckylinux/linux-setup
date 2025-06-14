#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
source "${toolpath}/load.sh"

# Disable swap
swapoff -a

# Restore /etc/resolv.conf
if [[ ! -L "${destination}/etc/resolv.conf" ]]
then
    # Echo
    echo "Restore ${destination}/etc/resolv.conf"

    # Remove quixk Fix for Chroot Environment
    if [[ -f "${destination}/etc/resolv.conf" ]]
    then
        rm "${destination}/etc/resolv.conf"
    fi

    if [[ -L "${destination}/etc/resolv.conf.systemd" ]]
    then
        # Restore Symlink to /etc/resolv.conf.systemd
        mv "${destination}/etc/resolv.conf.systemd" "${destination}/etc/resolv.conf"
    fi
fi

# Umount proc, sys, dev
source ${toolpath}/modules/umount_bind.sh

# Umount root/boot
for disk in "${disks[@]}"
do
    # Get EFI Mount Path
    efi_mount_path=$(get_efi_mount_path "${disk}")

    if mountpoint -q "${destination}${efi_mount_path}"
    then
        umount -R "${destination}${efi_mount_path}"
    fi
done

if mountpoint -q "${destination}/boot"
then
    umount -R "${destination}/boot"
fi

if mountpoint -q "${destination}"
then
    umount -R "${destination}"
fi

# Try to unmount all ZFS filesystems first
if [[ $(command -v zfs) ]]
then
    zfs umount -a
fi

# Kill all processes that keep ${rootpool} busy
# grep -i rpool /proc/*/mounts shows additional PID that are NOT shown by `mount -l`
mapfile processes < <(grep -i ${rootpool} /proc/*/mounts)
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
if [ "${rootfs}" == "zfs" ]
then
    if [[ $(command -v zfs) ]]
    then
        zfs umount -a
    fi

    if [[ $(command -v zpool) ]]
    then
        zpool export -f ${rootpool}
    fi
fi

if [ "${bootfs}" == "zfs" ]
then
    if [[ $(command -v zfs) ]]
    then
        zfs umount -a
    fi

    if [[ $(command -v zpool) ]]
    then
        zpool export -f ${bootpool}
    fi
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
