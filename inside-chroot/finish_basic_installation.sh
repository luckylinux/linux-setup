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

# Store current Path
currentpath=$(pwd)

# Update APT
apt-get update

# Configure locales and timezone
apt-get install --yes locales
dpkg-reconfigure locales
dpkg-reconfigure tzdata

# Install BASH-completion Package
apt-get install --yes bash-completion

# Fix /etc/resolv.conf
if [[ "${nsconfig}" == "resolv.conf" ]]
then
    # Echo
    echo "Configuring Nameservers using resolvconf: /etc/resolv.conf"

    # Make it modifiable (in case of e.g. executing Script multiple Times)
    chattr -i /etc/resolv.conf

    # Remove existing configuration
    rm -f /etc/resolv.conf

    # Add specified nameservers
    echo "nameserver ${ns1}" >> /etc/resolv.conf
    echo "nameserver ${ns2}" >> /etc/resolv.conf

    # Prervent automatic overriding
    chattr +i /etc/resolv.conf
elif [[ "${nsconfig}" == "systemd-resolved" ]]
then
    # Echo
    echo "Configuring Nameservers using systemd-resolved: /etc/systemd/resolved.conf"

    # Install systemd-resolved
    apt-get install --yes systemd-resolved
    systemctl enable systemd-resolved
    systemctl restart systemd-resolved

    # Set DNS Servers in systemd-resolved
    sed -Ei "s|^#DNS=|DNS=${ns1} ${ns2}|g" /etc/systemd/resolved.conf

    # Remove /etc/resolv.conf and ensure it's a link to systemd-resolved
    rm -r /etc/resolv.conf
    currentpath=$(pwd)
    cd /etc
    ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    cd $currentpath || exit
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
source ${toolpath}/modules/configure_boot_partition.sh

# Configure EFI Partition & /etc/fstab
source ${toolpath}/modules/configure_efi_partition.sh

# Configure root Partition & /etc/fstab
source ${toolpath}/modules/configure_root_partition.sh

# Configure data Partition & /etc/fstab
if [[ "${separate_data}" == "yes" ]]
then
    source ${toolpath}/modules/configure_data_partition.sh
fi

# Umount /boot/efi/<disk> to start "Clean"
for disk in "${disks[@]}"
do
    # Get EFI Mount Path
    efi_mount_path=$(get_efi_mount_path "${disk}")

    umount "/boot/efi/${disk}"
done

# Mount /boot if not already mounted
if mountpoint -q "/boot"
then
    x=1     # Silent
else
    # Not mounted yet
    # Make sure that a filesystem is mounted at /boot
    chattr +i /boot

    # Mount it
    mount /boot

    # Create required Folders
    mkdir -p /boot/efi
    mkdir -p /boot/grub

    # Make sure that /boot/efi is writable
    chattr -i /boot/efi

    # Make sure that nothing is currently mounted at /boot/efi
    if mountpoint -q "${destination}/boot/efi"
    then
        umount /boot/efi
    fi
fi


for disk in "${disks[@]}"
do
    # Get EFI Mount Path
    efi_mount_path=$(get_efi_mount_path "${disk}")

    # Create Required Subfolder
    mkdir -p "${efi_mount_path}"

    # Make sure that a filesystem is mounted at /boot/efi
    chattr +i "${efi_mount_path}"

    # Mount /boot/efi/<disk>
    mount "${efi_mount_path}"
done


# Install additionnal tools
apt-get install --yes aptitude
apt-get install --yes net-tools

# Install DHClient so we are sure that Networking gets set up properly and do NOT get locked out of the Server
apt-get install --yes isc-dhcp-client

# Install initramfs-tools
apt-get install --yes initramfs-tools

# Install partitioning tool and linux kernel
apt-get install --yes linux-headers-$(uname -r)
apt-get install --yes gdisk linux-image-amd64

# Install ZFS
apt-get install --yes zfs-dkms zfs-initramfs

# Install nfs-client, wget, ssh, sudo and curl
apt-get install --yes nfs-client wget ssh sudo curl
systemctl enable ssh

# Allow SSH Root Login via Password Authentication until a safer Way is setup after reboot
sed -Ei "s|#?PermitRootLogin(.*?)$|PermitRootLogin yes|g" /etc/ssh/sshd_config

# Ensure that NFS tools are mounted if applicable
#if [ -d "/tools_nfs" ]
if [[ "$setupnfstools" == "yes" ]]
then
	mount /tools_nfs
fi

if [ "$bootfs" == "zfs" ]
then
	# Setup GRUB Testing to ensure that ZFS ${bootpool} works correctly
	#currentpath=$(pwd)
	#cd /tools_nfs/Debian
	#bash setup_grub_testing.sh
	#apt-get update
	#cd $currentpath

	# Enable importing ${bootpool}
	tee /etc/systemd/system/zfs-import-${bootpool}.service << EOF
[Unit]
DefaultDependencies=no
Before=zfs-import-scan.service
Before=zfs-import-cache.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/zpool import -N -o cachefile=none ${bootpool}
# Work-around to preserve zpool cache:
ExecStartPre=-/bin/mv /etc/zfs/zpool.cache /etc/zfs/preboot_zpool.cache
ExecStartPost=-/bin/mv /etc/zfs/preboot_zpool.cache /etc/zfs/zpool.cache

[Install]
WantedBy=zfs-import.target
EOF



	systemctl enable zfs-import-${bootpool}.service
fi

# Install kernel
apt-get install --yes linux-image-amd64

# Set root password
echo "Setting root password"
passwd

# Remove os-prober package
apt-get remove --yes os-prober

# Tell Initramfs to use custom keyboard
echo "# Tell Initramfs to use custom keyboard" >> "/etc/initramfs-tools/initramfs.conf"
echo "KEYMAP=Y" >> "/etc/initramfs-tools/initramfs.conf"

# Reconfigure System (Install Bootloader, configure /etc/fstab, /etc/mdadm/mdadm.conf, ...)
source ${toolpath}/inside-chroot/reconfigure_system.sh

# Enable /etc/rc.local
# This calls dhclient to automatically get an IP Address, which should prevent us from getting locked out of the server
source ${toolpath}/modules/enable_rc_local.sh

if [ "$bootfs" == "zfs" ]
then
	# Disable grub fallback service
	# Typically only needed for  mirror or raidz topology:
	systemctl mask grub-initrd-fallback.service
fi

# Verify that the ZFS module is installed
echo "!!! CHECK THAT THE ZFS MODULE IS INSTALLED !!!"
ls /boot/grub/*/zfs.mod

# Verify that the ZFS root filesystem is recognised
grub-probe /

# Update initramfs
update-initramfs -u -k all

# Setup Secure Boot
if [ "${secureboot}" == "yes" ]
then
    source ${toolpath}/inside-chroot/setup_secure_boot.sh
fi

# Snapshot the initial installation
if [ "${bootfs}" == "zfs" ]
then
    zfs snapshot -r ${bootpool}/BOOT/${distribution}@install
fi

if [ "${rootfs}" == "zfs" ]
then
    zfs snapshot ${rootpool}/ROOT/${distribution}@install
fi
