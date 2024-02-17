#!/bin/bash

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ] 
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load Configuration
source $toolpath/config.sh

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
echo "${disk1}_crypt" UUID=$(blkid -s UUID -o value ${device1}-part4) none \
    luks,discard,initramfs > "/etc/crypttab"

echo "${disk2}_crypt" UUID=$(blkid -s UUID -o value ${device2}-part4) none \
    luks,discard,initramfs >> "/etc/crypttab"

# (Re)Install Bootloader
source $toolpath/inside-chroot/install_bootloader.sh

# Setup automatic disk unlock
if [ "$clevisautounlock" == "yes" ]
then
    source $toolpath/modules/setup_clevis_nbde.sh
fi

# Update initramfs
update-initramfs -c -k all
