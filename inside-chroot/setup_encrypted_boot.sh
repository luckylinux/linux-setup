#!/bin/bash

# Load configuration
source ../config.sh

# Update ZFS pool cache
mkdir -p /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/$bootpool
touch /etc/zfs/zfs-list.cache/$rootpool
zed -F &

# Wait a few seconds
sleep 5

# Kill ZED
killall zed

# Cat
echo "============================================================="
echo "========================= BOOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/$bootpool

# Cat
echo "============================================================="
echo "========================= ROOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/$rootpool

# Stop ZED
#fg
# CTRL+C

# Replace $destination (e.g. /mnt/debian, /mnt/ubuntu, ...) with /
sed -Ei "s|$destination/?|/|" /etc/zfs/zfs-list.cache/*

# Replace // / for boot
sed -Ei "s|//boot?|/boot|" /etc/zfs/zfs-list.cache/*

# Cat
echo "============================================================="
echo "========================= BOOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/$bootpool

# Cat
echo "============================================================="
echo "========================= ROOT POOL ========================="
echo "============================================================="
cat /etc/zfs/zfs-list.cache/$rootpool

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
source ./setup_clevis_nbde.sh

# Update initramfs
update-initramfs -c -k all
