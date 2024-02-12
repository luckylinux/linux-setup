#!/bin/bash

# Load configuration
source ../config.sh

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

# Update GRUB
update-grub

# Check that it's ZFS
grub-probe /boot

# (Re)install GRUB
grub-install $device1
grub-install $device1
grub-install $device2
grub-install $device2

# Update GRUB once again
update-grub

# Setup automatic disk unlock
if [ "$clevisautounlock" == "yes" ]
then
    source ./setup_clevis_nbde.sh
fi

# Update initramfs
update-initramfs -c -k all