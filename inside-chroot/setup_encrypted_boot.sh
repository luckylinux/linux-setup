#!/bin/bash

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ] 
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source $toolpath/load.sh

# Update ZFS pool cache
mkdir -p /etc/zfs/zfs-list.cache

if [ "$bootfs" == "zfs" ]
then
    touch /etc/zfs/zfs-list.cache/$bootpool
fi

if [ "$rootfs" == "zfs" ]
then
    touch /etc/zfs/zfs-list.cache/$rootpool
fi

zed -F &

# Wait a few seconds
sleep 5

# Kill ZED
killall zed

# Cat
if [ "$bootfs" == "zfs" ]
then
    echo "============================================================="
    echo "========================= BOOT POOL ========================="
    echo "============================================================="
    cat /etc/zfs/zfs-list.cache/$bootpool
fi

# Cat
if [ "$rootfs" == "zfs" ]
then
    echo "============================================================="
    echo "========================= ROOT POOL ========================="
    echo "============================================================="
    cat /etc/zfs/zfs-list.cache/$rootpool
fi

if [ "$rootfs" == "zfs" ] || [ "$bootfs" == "zfs" ]
then
    # Replace $destination (e.g. /mnt/debian, /mnt/ubuntu, ...) with /
    sed -Ei "s|$destination/?|/|" /etc/zfs/zfs-list.cache/*
fi

if [ "$bootfs" == "zfs" ]
then
    # Replace // / for boot
    sed -Ei "s|//boot?|/boot|" /etc/zfs/zfs-list.cache/*
fi

# Cat
if [ "$bootfs" == "zfs" ]
then
    echo "============================================================="
    echo "========================= BOOT POOL ========================="
    echo "============================================================="
    cat /etc/zfs/zfs-list.cache/$bootpool
fi

# Cat
if [ "$rootfs" == "zfs" ]
then
    echo "============================================================="
    echo "========================= ROOT POOL ========================="
    echo "============================================================="
    cat /etc/zfs/zfs-list.cache/$rootpool
fi

# Enable Disk in Crypttab for initramfs
echo "${disk1}_root_crypt" UUID=$(blkid -s UUID -o value ${device1}-part${root_num}) none \
    luks,discard,initramfs > "/etc/crypttab"

echo "${disk2}_root_crypt" UUID=$(blkid -s UUID -o value ${device2}-part${root_num}) none \
    luks,discard,initramfs >> "/etc/crypttab"

# (Re)Install Bootloader
source $toolpath/inside-chroot/install_bootloader.sh

# Setup automatic Disk Unlock
if [ "$clevisautounlock" == "yes" ]
then
    source $toolpath/modules/setup_clevis_nbde.sh
fi

# Setup remote Disk Unlock
if [ "$dropbearunlock" == "yes" ]
then
    source $toolpath/modules/setup_dropbear_unlock.sh
fi

# Update initramfs
update-initramfs -c -k all
