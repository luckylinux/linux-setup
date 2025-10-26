#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Create Separate Datasets
mkdir -p ${destination}/srv
if ! mountpoint -q "${destination}/srv"
then
    chattr +i ${destination}/srv
fi
zfs create -o com.ubuntu.zsys:bootfs=no \
    ${rootpool}/ROOT/$distribution/srv
zfs mount ${rootpool}/ROOT/$distribution/srv


mkdir -p ${destination}/usr
if ! mountpoint -q "${destination}/usr"
then
    chattr +i ${destination}/usr
fi
zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=on \
    ${rootpool}/ROOT/$distribution/usr
zfs mount ${rootpool}/ROOT/$distribution/usr


mkdir -p ${destination}/usr/local
if ! mountpoint -q "${destination}/usr/local"
then
    chattr +i ${destination}/usr/local
fi
zfs create ${rootpool}/ROOT/$distribution/usr/local
zfs mount ${rootpool}/ROOT/$distribution/usr/local


mkdir -p ${destination}/var
if ! mountpoint -q "${destination}/var"
then
    chattr +i ${destination}/var
fi
zfs create -o com.ubuntu.zsys:bootfs=no -o canmount=on \
    ${rootpool}/ROOT/$distribution/var
zfs mount ${rootpool}/ROOT/$distribution/var


mkdir -p ${destination}/var/games
if ! mountpoint -q "${destination}/var/games"
then
    chattr +i ${destination}/var/games
fi
zfs create ${rootpool}/ROOT/$distribution/var/games
zfs mount ${rootpool}/ROOT/$distribution/var/games


mkdir -p ${destination}/var/lib
if ! mountpoint -q "${destination}/var/lib"
then
    chattr +i ${destination}/var/lib
fi
zfs create ${rootpool}/ROOT/$distribution/var/lib
zfs mount ${rootpool}/ROOT/$distribution/var/lib


mkdir -p ${destination}/var/lib/AccountsService
if ! mountpoint -q "${destination}/var/lib/AccountsService"
then
    chattr +i ${destination}/var/lib/AccountsService
fi
zfs create ${rootpool}/ROOT/$distribution/var/lib/AccountsService
zfs mount ${rootpool}/ROOT/$distribution/var/lib/AccountsService


mkdir -p ${destination}/var/lib/apt
if ! mountpoint -q "${destination}/var/lib/apt"
then
    chattr +i ${destination}/var/lib/apt
fi
zfs create ${rootpool}/ROOT/$distribution/var/lib/apt
zfs mount ${rootpool}/ROOT/$distribution/var/lib/apt


mkdir -p ${destination}/var/lib/dpkg
if ! mountpoint -q "${destination}/var/lib/dpkg"
then
    chattr +i ${destination}/var/lib/dpkg
fi
zfs create ${rootpool}/ROOT/$distribution/var/lib/dpkg
zfs mount ${rootpool}/ROOT/$distribution/var/lib/dpkg


mkdir -p ${destination}/var/lib/NetworkManager
if ! mountpoint -q "${destination}/var/lib/NetworkManager"
then
    chattr +i ${destination}/var/lib/NetworkManager
fi
zfs create ${rootpool}/ROOT/$distribution/var/lib/NetworkManager
zfs mount ${rootpool}/ROOT/$distribution/var/lib/NetworkManager


mkdir -p ${destination}/var/log
if ! mountpoint -q "${destination}/var/log"
then
    chattr +i ${destination}/var/log
fi

zfs create ${rootpool}/ROOT/$distribution/var/log
zfs mount ${rootpool}/ROOT/$distribution/var/log


mkdir -p ${destination}/var/mail
if ! mountpoint -q "${destination}/var/mail"
then
    chattr +i ${destination}/var/mail
fi

zfs create ${rootpool}/ROOT/$distribution/var/mail
zfs mount ${rootpool}/ROOT/$distribution/var/mail


mkdir -p ${destination}/var/snap
chattr +i ${destination}/var/snap
#zfs create ${rootpool}/ROOT/$distribution/var/snap


mkdir -p ${destination}/var/spool
if ! mountpoint -q "${destination}/var/spool"
then
    chattr +i ${destination}/var/spool
fi

zfs create ${rootpool}/ROOT/$distribution/var/spool
zfs mount ${rootpool}/ROOT/$distribution/var/spool


mkdir -p ${destination}/var/www
if ! mountpoint -q "${destination}/var/www"
then
    chattr +i ${destination}/var/www
fi

zfs create ${rootpool}/ROOT/$distribution/var/www
zfs mount ${rootpool}/ROOT/$distribution/var/www



zfs create -o canmount=off -o mountpoint=/ \
    ${rootpool}/USERDATA



mkdir -p ${destination}/var/lib/libvirt
if ! mountpoint -q "${destination}/var/lib/libvirt"
then
    chattr +i ${destination}/var/lib/libvirt
fi

zfs create ${rootpool}/ROOT/$distribution/var/lib/libvirt
zfs mount ${rootpool}/ROOT/$distribution/var/lib/libvirt



mkdir -p ${destination}/root
if ! mountpoint -q "${destination}/root"
then
    chattr +i ${destination}/root
fi

zfs create -o com.ubuntu.zsys:bootfs-datasets=rpool/ROOT/$distribution \
    -o canmount=on -o mountpoint=/root \
    ${rootpool}/USERDATA/root
zfs mount ${rootpool}/USERDATA/root



mkdir -p ${destination}/tmp
if ! mountpoint -q "${destination}/tmp"
then
    chattr +i ${destination}/tmp
fi

zfs create -o com.ubuntu.zsys:bootfs=no \
    ${rootpool}/ROOT/$distribution/tmp
zfs mount ${rootpool}/ROOT/$distribution/tmp



# Create data dataset
#mkdir -p ${destination}/data
#chattr +i ${destination}/data
#zfs create -o canmount=off -o mountpoint=none ${rootpool}/data
