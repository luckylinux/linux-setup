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
    if [ "${rootfs}" == "zfs" ] || [ "${bootfs}" == "zfs" ]
    then
        source ${toolpath}/modules/setup_zfs_backports.sh
    fi
fi

# Install system tools
apt-get install --yes aptitude nload htop lm-sensors net-tools debootstrap dosfstools e2fsprogs

# Install partition management tools
apt-get install --yes gdisk parted

# Install mdadm
if [ "${bootfs}" != "zfs" ] && [ ${numdisks_total} -gt 1 ]
then
    apt-get install --yes mdadm
fi

# Install cryptsetup / LUKS
if [ "${encryptrootfs}" == "luks" ] || [ "${encryptdatafs}" == "yes" ]
then
    apt-get install --yes cryptsetup
fi

# Install clevis
if [[ "${clevisautounlock}" == "yes" ]]
then
    apt-get install --yes clevis clevis-luks clevis-initramfs cryptsetup-initramfs
fi

# Install ZFS
if [ "${rootfs}" == "zfs" ] || [ "${bootfs}" == "zfs" ]
then
    apt-get install --yes zfsutils-linux zfs-zed zfs-dkms
fi

# Fix MDADM automount
if [[ -f /etc/mdadm/mdadm.conf ]]
then
    echo "Disabling automatic mounting in /etc/mdadm/mdadm.conf"
    sed -i -e 's/\#DEVICE partitions containers/DEVICE \/dev\/null/g' '/etc/mdadm/mdadm.conf'
fi

# Enable mdadm service with systemd
# If this is a link remove it
if [ -L /lib/systemd/system/mdadm.service ]
then
	echo "Removing /lib/systemd/system/mdadm.service in order to unmask mdadm service" 
	rm /lib/systemd/system/mdadm.service

	echo "Reload systemd daemon"
	systemctl daemon-reload
fi
