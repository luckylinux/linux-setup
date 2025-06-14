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
source "${toolpath}/load.sh"

# Setup system groups
addgroup --system lpadmin
addgroup --system lxd
addgroup --system sambashare

# Setup user
read -p "Enter username: " username

adduser "$username"
usermod -a -G adm,cdrom,dip,lpadmin,lxd,plugdev,sambashare,sudo $username

# Create user Dataset
ROOT_DS=$(zfs list -o name | awk '/ROOT\/$distribution/{print $1;exit}')

mkdir -p "/home/${username}"

chattr +i "/home/${username}"

zfs create -o com.$distribution.zsys:bootfs-datasets=$ROOT_DS \
    -o canmount=on -o mountpoint="/home/${username}" \
    "${rootpool}/USERDATA/${username}"

mkdir -p "/home/${username}"

#cp -a /etc/skel/. "/home/${username}"
chown -R "${username}:${username}" "/home/${username}"

#chattr +i "/home/${username}"

zfs mount "${rootpool}/USERDATA/${username}"

chown -R "${username}:${username}" "/home/${username}"

# Fix filesystem mount ordering
mkdir /etc/zfs/zfs-list.cache

if [ "${bootfs}" == "zfs" ]
then
    touch /etc/zfs/zfs-list.cache/${bootpool}
fi

if [ "${rootfs}" == "zfs" ]
then
    touch /etc/zfs/zfs-list.cache/${rootpool}
fi

ln -s /usr/lib/zfs-linux/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d
zed -F &

sleep 2

# Replace $destination (e.g. /mnt/debian, /mnt/ubuntu, ...) with /
sed -Ei "s|$destination/?|/|" /etc/zfs/zfs-list.cache/*

# Replace // / for boot
sed -Ei "s|//boot?|/boot|" /etc/zfs/zfs-list.cache/*

# Setup MATE desktop
install_packages_unattended ubuntu-mate-desktop

# Setup XFCE desktop
install_packages_unattended xubuntu-desktop

# Install LXQT desktop
install_packages_unattended lubuntu-desktop

# Install X2GO server&client
install_packages_unattended x2goserver x2goclient

# Install Xorg
install_packages_unattended xorg

# Install NVIDIA drivers
# install_packages_unattended nvidia-drivers-440

# Install nano
install_packages_unattended nano

# Install cryptsetup
install_packages_unattended cryptsetup

# Install fat32 tools
install_packages_unattended dosfstools

# Install ZFS on Linux
install_packages_unattended linux-image-generic zfs-initramfs zfs-dkms zfs-auto-snapshot zfs-zed # zsys

# Remove snapd
purge_packages_unattended snapd
apt-get hold snapd
autoremove_packages

# Remove net plan
purge_packages_unattended netplan.io
apt-get hold netplan.io
autoremove_packages

# Install kernel
install_packages_unattended linux-image-generic

# Regerenate initramfs
regenerate_initrd

# Install ifupdown
install_packages_unattended ifupdown-extra

# Install development tools
install_packages_unattended bison flex build-essential libelf-dev libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf uuid-dev # build-dep 

# Disable grub fallback service
# Typically only needed for  mirror or raidz topology:
systemctl mask grub-initrd-fallback.service

# Patch dependency loop due to ZFS on top of LUKS
install_packages_unattended curl patch
curl https://launchpadlibrarian.net/478315221/2150-fix-systemd-dependency-loops.patch | \
    sed "s|/etc|/lib|;s|\.in$||" | (cd / ; patch -p1)
