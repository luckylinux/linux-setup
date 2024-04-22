#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

######################################################
# Install Requirements on the Currently Running HOST #
######################################################

# Hetzner ZFS Fix
# This will remove their /usr/local/sbin/zfs dummy Package since we install directly from Debian Backports
if [[ "$hetznerzfsfix" == "yes" ]]
then
   if [[ -f "/usr/local/sbin/zfs" ]]
   then
      #chattr -i /usr/local/sbin/zfs
      #rm -f /usr/local/sbin/zfs

      #echo "Please Close your SSH Session Now and Login Again"
      #echo "This is required to remove all References to the old /usr/local/sbin/zfs alias"

      #exit 9
   fi

      # Load default Profile from the Distribution
      source /etc/skel/.bashrc

      # Disable weird Echo
      shopt -u progcomp
      shopt -u extdebug
      shopt -u xpg_echo

      # Make sure that PATH does NOT include stuff from /usr/local/bin and /usr/local/sbin
      export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
fi

# Configure Backports if Required
# Must be perfomed also on the Host if the Guest uses Backports
if [[ "${usezfsbackports}" == "yes" ]]
then
    source ${toolpath}/modules/setup_zfs_backports.sh
fi

# Install system tools
apt-get install --yes aptitude nload htop lm-sensors net-tools debootstrap

# Install partition management tools
apt-get install --yes gdisk parted

# Install mdadm
apt-get install --yes mdadm

# Install cryptsetup / LUKS
apt-get install --yes cryptsetup

# Install ZFS
apt-get install --yes zfsutils-linux zfs-zed zfs-auto-snapshot zfs-dkms

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
