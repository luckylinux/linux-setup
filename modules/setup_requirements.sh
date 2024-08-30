#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

######################################################
# Install Requirements on the Currently Running HOST #
######################################################

# Configure Backports if Required
# Must be perfomed also on the Host if the Guest uses Backports
if [[ "${usezfsbackports}" == "yes" ]]
then
    source ${toolpath}/modules/setup_zfs_backports.sh
fi

# Install system tools
apt-get install --yes aptitude nload htop lm-sensors net-tools debootstrap dosfstools e2fsprogs

# Install partition management tools
apt-get install --yes gdisk parted

# Install mdadm
apt-get install --yes mdadm

# Install cryptsetup / LUKS
apt-get install --yes cryptsetup

# Install clevis
apt-get install --yes clevis clevis-luks clevis-initramfs cryptsetup-initramfs

# Install ZFS
apt-get install --yes zfsutils-linux zfs-zed zfs-dkms

# Fix MDADM automount
echo "Disabling automatic mounting in /etc/mdadm/mdadm.conf"
sed -i -e 's/\#DEVICE partitions containers/DEVICE \/dev\/null/g' '/etc/mdadm/mdadm.conf'

# Enable mdadm service with systemd
# If this is a link remove it
if [ -L /lib/systemd/system/mdadm.service ]
then
	echo "Removing /lib/systemd/system/mdadm.service in order to unmask mdadm service" 
	rm /lib/systemd/system/mdadm.service

	echo "Reload systemd daemon"
	systemctl daemon-reload
fi
