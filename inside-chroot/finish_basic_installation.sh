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
source $toolpath/config.sh

# Fix /etc/resolv.conf
if [ "$nsconfig" == "resolv.conf" ]
then
    # Remove existing configuration
    rm -f /etc/resolv.conf

    # Add specified nameservers
    echo "nameserver $ns1" >> /etc/resolv.conf
    echo "nameserver $ns2" >> /etc/resolv.conf

    # Prervent automatic overriding
    chattr +i /etc/resolv.conf
elif [ "$nsconfig" == "systemd-resolved" ]
    # Install systemd-resolved
    apt-get install --yes systemd-resolved
    systemctl enable systemd-resolved
    systemctl restart systemd-resolved

    # Set DNS Servers in systemd-resolved
    sed -Ei "s/^#DNS=/DNS=$ns1 $ns2/g" /etc/systemd/resolved.conf

    # Store current Path
    currentpath=$(pwd)

    # Remove /etc/resolv.conf and ensure it's a link to systemd-resolved
    rm -r /etc/resolv.conf
    currentpath=$(pwd)
    cd /etc
    ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    cd $currentpath
else
    echo "Invalid Nameserver Configuration. <nsconfig> must be one of the following options: <resolv.conf> or <systemd-resolved>. Aborting !"
    exit 1
fi

# ...
ln -s /proc/self/mounts /etc/mtab

# Install Backports if so Requested
if [[ "${usezfsbackports}" == "yes" ]]
then
    source ${toolpath}/modules/setup_zfs_backports.sh
fi

# Configure /boot Partition & /etc/fstab
source $toolpath/modules/configure_boot_partition.sh

# Configure EFI Partition & /etc/fstab
source $toolpath/modules/configure_efi_partition.sh

# Configure / Partition & /etc/fstab
source $toolpath/modules/configure_root_partition.sh

# Mount /boot
chattr +i /boot
mount /boot
mkdir -p /boot/efi
mkdir -p /boot/grub
chattr +i /boot/efi
mount /boot/efi

# Update APT
apt-get update

# Configure locales
apt-get install --yes locales
dpkg-reconfigure locales
dpkg-reconfigure tzdata

# Install additionnal tools
apt-get install --yes aptitude
apt-get install --yes net-tools

# Install DHClient so we are sure that Networking gets set up properly and do NOT get locked out of the Server
apt-get install --yes isc-dhcp-client

# Install partitioning tool and linux kernel
apt-get install --yes gdisk linux-headers-$(uname -r) linux-image-amd64

# Install ZFS
apt-get install --yes zfs-dkms zfs-initramfs

# Install nfs-client, wget, ssh, sudo and curl
apt-get install --yes nfs-client wget ssh sudo curl
systemctl enable ssh

# Ensure that NFS tools are mounted if applicable
#if [ -d "/tools_nfs" ]
if [[ "$setupnfstools" == "yes" ]]
then
	mount /tools_nfs
fi

if [ "$bootfs" == "zfs" ]
then
	# Setup GRUB Testing to ensure that ZFS $bootpool works correctly
	#currentpath=$(pwd)
	#cd /tools_nfs/Debian
	#bash setup_grub_testing.sh
	#apt-get update
	#cd $currentpath

	# Enable importing $bootpool
	tee /etc/systemd/system/zfs-import-$bootpool.service << EOF
[Unit]
DefaultDependencies=no
Before=zfs-import-scan.service
Before=zfs-import-cache.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/zpool import -N -o cachefile=none $bootpool
# Work-around to preserve zpool cache:
ExecStartPre=-/bin/mv /etc/zfs/zpool.cache /etc/zfs/preboot_zpool.cache
ExecStartPost=-/bin/mv /etc/zfs/preboot_zpool.cache /etc/zfs/zpool.cache

[Install]
WantedBy=zfs-import.target
EOF



	systemctl enable zfs-import-$bootpool.service
fi

# Install kernel
apt-get install --yes linux-image-amd64

# Set root password
echo "Setting root password"
passwd

# Remove os-prober package
apt-get remove --yes os-prober

# Verify that the ZFS root filesystem is recognised
grub-probe /

# Update initramfs
update-initramfs -u -k all

# Tell Initramfs to use custom keyboard
echo "# Tell Initramfs to use custom keyboard" >> "/etc/initramfs-tools/initramfs.conf"
echo "KEYMAP=Y" >> "/etc/initramfs-tools/initramfs.conf"

# Reconfigure System (Install Bootloader, configure /etc/fstab, /etc/mdadm/mdadm.conf, ...)
source $toolpath/inside-chroot/reconfigure_system.sh

if [ "$bootfs" == "zfs" ]
then
	# Disable grub fallback service
	# Typically only needed for  mirror or raidz topology:
	systemctl mask grub-initrd-fallback.service
fi

# Verify that the ZFS module is installed
echo "!!! CHECK THAT THE ZFS MODULE IS INSTALLED !!!"
ls /boot/grub/*/zfs.mod

# Snapshot the initial installation
if [ "$bootfs" == "zfs" ]
then
    zfs snapshot -r $bootpool/BOOT/$distribution@install
fi

if [ "$rootfs" == "zfs" ]
then
    zfs snapshot $rootpool/ROOT/$distribution@install
fi
