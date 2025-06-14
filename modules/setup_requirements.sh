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

# Install Distribution-specific Packages
if [[ $(get_os_family) == "debian" ]]
then
    # Install Debian Tools
    install_packages_unattended aptitude debootstrap lm-sensors
elif [[ $(get_os_family) == "fedora" ]]
then
    # Nothing Special required for Fedora
    # x=1

    # Install lm-sensors for Fedora
    install_packages_unattended lm_sensors
fi

# Install Common System Tools
install_packages_unattended nload htop net-tools dosfstools e2fsprogs psmisc tmux screen

# Install partition management tools
install_packages_unattended gdisk parted

# Install mdadm
if [ "${bootfs}" != "zfs" ] && [ ${numdisks_total} -gt 1 ]
then
    install_packages_unattended mdadm
fi

# Install cryptsetup / LUKS
if [ "${encryptrootfs}" == "luks" ] || [ "${encryptdatafs}" == "yes" ]
then
    install_packages_unattended cryptsetup
fi

# Install clevis
if [[ "${clevisautounlock}" == "yes" ]]
then
    install_packages_unattended clevis clevis-luks clevis-initramfs cryptsetup-initramfs
fi

# Install ZFS
if [ "${rootfs}" == "zfs" ] || [ "${bootfs}" == "zfs" ]
then
    install_packages_unattended zfsutils-linux zfs-zed zfs-dkms
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
