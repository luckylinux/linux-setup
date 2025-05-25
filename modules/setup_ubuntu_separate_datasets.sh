#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Create Separate Datasets
mkdir -p ${destination}/srv
chattr +i ${destination}/srv
zfs create -o com.ubuntu.zsys:bootfs=no \
    ${rootpool}/ROOT/$distribution/srv


mkdir -p ${destination}/usr
chattr +i ${destination}/usr
zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=on \
    ${rootpool}/ROOT/$distribution/usr


mkdir -p ${destination}/usr
chattr +i ${destination}/usr
zfs create ${rootpool}/ROOT/$distribution/usr/local


mkdir -p ${destination}/var
chattr +i ${destination}/var
zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=on \
    ${rootpool}/ROOT/$distribution/var


mkdir -p ${destination}/srv
chattr +i ${destination}/srv
zfs create ${rootpool}/ROOT/$distribution/var/games


mkdir -p ${destination}/var/lib
chattr +i ${destination}/var/lib
zfs create ${rootpool}/ROOT/$distribution/var/lib


mkdir -p ${destination}/var/lib/AccountsService
chattr +i ${destination}/var/lib/AccountsService
zfs create ${rootpool}/ROOT/$distribution/var/lib/AccountsService


mkdir -p ${destination}/var/lib/apt
chattr +i ${destination}/var/lib/apt
zfs create ${rootpool}/ROOT/$distribution/var/lib/apt


mkdir -p ${destination}/var/lib/dpkg
chattr +i ${destination}/var/lib/dpkg
zfs create ${rootpool}/ROOT/$distribution/var/lib/dpkg


mkdir -p ${destination}/var/lib/NetworkManager
chattr +i ${destination}/var/lib/NetworkManager
zfs create ${rootpool}/ROOT/$distribution/var/lib/NetworkManager


mkdir -p ${destination}/var/log
chattr +i ${destination}/var/log
zfs create ${rootpool}/ROOT/$distribution/var/log


mkdir -p ${destination}/var/mail
chattr +i ${destination}/var/mail
zfs create ${rootpool}/ROOT/$distribution/var/mail


mkdir -p ${destination}/var/snap
chattr +i ${destination}/var/snap
#zfs create ${rootpool}/ROOT/$distribution/var/snap


mkdir -p ${destination}/var/spool
chattr +i ${destination}/var/spool
zfs create ${rootpool}/ROOT/$distribution/var/spool


mkdir -p ${destination}/var/www
chattr +i ${destination}/var/www
zfs create ${rootpool}/ROOT/$distribution/var/www



zfs create -o canmount=off -o mountpoint=/ \
    ${rootpool}/USERDATA



mkdir -p ${destination}/var/www
chattr +i ${destination}/var/www
zfs create ${rootpool}/ROOT/$distribution/var/lib/libvirt



mkdir -p ${destination}/root
chattr +i ${destination}/root
zfs create -o com.ubuntu.zsys:bootfs-datasets=rpool/ROOT/$distribution \
    -o canmount=on -o mountpoint=/root \
    ${rootpool}/USERDATA/root



mkdir -p ${destination}/tmp
chattr +i ${destination}/tmp
zfs create -o com.ubuntu.zsys:bootfs=no \
    ${rootpool}/ROOT/$distribution/tmp




# Create data dataset
#mkdir -p ${destination}/data
#chattr +i ${destination}/data
#zfs create -o canmount=off -o mountpoint=none ${rootpool}/data
