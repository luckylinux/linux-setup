#!/bin/bash

# Create Separate Datasets
zfs create -o com.ubuntu.zsys:bootfs=no \
    $rootpool/ROOT/$distribution/srv

zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=off \
    $rootpool/ROOT/$distribution/usr

zfs create $rootpoolt/ROOT/$distribution/usr/local

zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=off \
    $rootpool/ROOT/$distribution/var

zfs create $rootpool/ROOT/$distribution/var/games

zfs create $rootpool/ROOT/$distribution/var/lib

zfs create $rootpool/ROOT/$distribution/var/lib/AccountsService

zfs create $rootpool/ROOT/$distribution/var/lib/apt

zfs create $rootpool/ROOT/$distribution/var/lib/dpkg

zfs create $rootpool/ROOT/$distribution/var/lib/NetworkManager

zfs create $rootpool/ROOT/$distribution/var/log

zfs create $rootpool/ROOT/$distribution/var/mail

#zfs create $rootpool/ROOT/$distribution/var/snap

zfs create $rootpool/ROOT/$distribution/var/spool

zfs create $rootpool/ROOT/$distribution/var/www

zfs create -o canmount=off -o mountpoint=/ \
    $rootpool/USERDATA

zfs create -o com.ubuntu.zsys:bootfs-datasets=rpool/ROOT/$distribution \
    -o canmount=on -o mountpoint=/root \
    $rootpool/USERDATA/root

zfs create -o com.ubuntu.zsys:bootfs=no \
    $rootpool/ROOT/$distribution/tmp

# Create data dataset
#zfs create -o canmount=off -o mountpoint=none $rootpool/data
