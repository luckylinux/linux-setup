#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Reconfigure keyboard
dpkg-reconfigure keyboard-configuration
service keyboard-setup restart

# Upgrade the minimal system
apt-get -y dist-upgrade

# Remove linux-firmware-free
apt-get -y remove linux-firmware-free

# Add Proxmox VE repository
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Remove Proxmox VE enterprise repository
rm -f /etc/apt/sources.list.d/pve-enterprise.list*

# Add Proxmox VE repository key
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

# Update to include new sources
apt-get update

# Install Proxmox VE
apt-get install proxmox-ve postfix open-iscsi ifupdown2

# Remove Proxmox VE enterprise repository
rm -f /etc/apt/sources.list.d/pve-enterprise.list*

# Remove OS-prober
apt-get remove os-prober

# Remove linux-image-amd64
apt-get remove linux-image-amd64

# Also make sure to remove ZFS-DKMS since that referes to Debian Packages and is NOT part of Proxmox VE
echo "Remove ZFS-DKMS since that referes to Debian Packages and is NOT part of Proxmox VE"
apt-get remove zfs-dkms

# Configure PVE storage
tee /etc/pve/storage.cfg <<EOF
dir: local
        disable
        path /var/lib/vz
        content iso,vztmpl
        shared 0

zfspool: local-zfs
        pool $rootpool/data
        content images,rootdir
        sparse 1
EOF

# Remove Proxmox VE enterprise repository
rm -f /etc/apt/sources.list.d/pve-enterprise.list*

# Remove zfs-dkms from Debian Backports
rm -f /etc/apt/preferences.d/zfs-backports
apt-get remove -y zfs-dkms
apt-get -y dist-upgrade
