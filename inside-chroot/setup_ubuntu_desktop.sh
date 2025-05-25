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
apt-get install --yes ubuntu-mate-desktop

# Setup XFCE desktop
apt-get install --yes xubuntu-desktop

# Install LXQT desktop
apt-get install --yes lubuntu-desktop

# Install X2GO server&client
apt-get install --yes x2goserver x2goclient

# Install Xorg
apt-get install --yes xorg

# Install NVIDIA drivers
#apt-get install --yes nvidia-drivers-440

# Install nano
apt-get install --yes nano

# Install cryptsetup
apt-get install --yes cryptsetup

# Install fat32 tools
apt-get install --yes dosfstools

# Install ZFS on Linux
apt-get install --yes linux-image-generic zfs-initramfs zfs-dkms zfs-auto-snapshot zfs-zed # zsys

# Remove snapd
apt-get purge --yes snapd
apt-get hold snapd
apt-get autoremove

# Remove net plan
apt-get purge --yes netplan.io
apt-get hold netplan.io
apt-get autoremove

# Install kernel
apt-get install --yes linux-image-generic

# Regerenate initramfs
update-initramfs -k all -u

# Install ifupdown
apt-get install --yes ifupdown-extra

# Install development tools
apt-get install --yes bison flex build-essential libelf-dev libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf uuid-dev #build-dep 

# Disable grub fallback service
# Typically only needed for  mirror or raidz topology:
systemctl mask grub-initrd-fallback.service

# Patch dependency loop due to ZFS on top of LUKS
apt-get install --yes curl patch
curl https://launchpadlibrarian.net/478315221/2150-fix-systemd-dependency-loops.patch | \
    sed "s|/etc|/lib|;s|\.in$||" | (cd / ; patch -p1)
