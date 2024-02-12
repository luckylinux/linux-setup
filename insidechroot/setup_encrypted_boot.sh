#!/bin/bash

# Load configuration
source ../config.sh

# Update ZFS pool cache
mkdir -p /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/bpool
touch /etc/zfs/zfs-list.cache/rpool
zed -F &

# Wait a few seconds
sleep 5

# Kill ZED
killall zed

# Cat
echo "============================================================="
echo "========================= BOOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/bpool

# Cat
echo "============================================================="
echo "========================= ROOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/rpool

# Stop ZED
#fg
# CTRL+C

# Replace /mnt/debian with /
sed -Ei "s|$destination/?|/|" /etc/zfs/zfs-list.cache/*

# Replace // / for boot
sed -Ei "s|//boot?|/boot|" /etc/zfs/zfs-list.cache/*

# Cat
echo "============================================================="
echo "========================= BOOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/bpool

# Cat
echo "============================================================="
echo "========================= ROOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/rpool

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
source setup_clevis_nbde.sh

# Update initramfs
update-initramfs -c -k all
