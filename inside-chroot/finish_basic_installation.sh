#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load Configuration
source $toolpath/config.sh

# Mount /boot
chattr +i /boot
mount /boot
mkdir -p /boot/efi
mkdir -p /boot/grub
chattr +i /boot/efi
mount /boot/efi

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

# Update APT
apt-get update

# Configure locales
apt-get install --yes locales
dpkg-reconfigure locales
dpkg-reconfigure tzdata

# Install additionnal tools
apt-get install --yes aptitude
apt-get install --yes net-tools

# Install partitioning tool and linux kernel
apt-get install --yes gdisk linux-headers-$(uname -r) linux-image-amd64

# Install ZFS
apt-get install --yes zfs-dkms zfs-initramfs

# Install nfs-client, wget, ssh, sudo and curl
apt-get install --yes nfs-client wget ssh sudo curl
systemctl enable ssh

# Ensure that NFS tools are mounted if applicable
if [ -d "/tools_nfs" ]
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

	# Setup ZFS Backports to ensure that ZFS installed version is the same as the LiveUSB
	#currentpath=$(pwd)
	#cd /tools_nfs/Debian
	#bash setup_zfs_backports.sh
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

# Install GRUB to MBR
if [ "$bootloadermode" == "BIOS" ]
then
    # Install GRUB
    apt-get install --yes grub-pc

    # BIOS
    grub-install "${device1}"
    grub-install "${device2}"
elif [ "$bootloadermode" == "UEFI" ]
then
    # Install GRUB
    apt-get install --yes grub-efi-amd64

    # UEFI
    grub-install --target=x86_64-efi "${device1}"
    grub-install --target=x86_64-efi "${device2}"
    #grub-install --target=x86_64-efi --efi-directory=/boot/efi \
    #--bootloader-id=ubuntu --recheck --no-floppy
else
    # Not Supported
    echo "Error - bootloadermode <${bootloadermode}> is NOT supported. Aborting"
    exit 1
fi

# Update GRUB configuration
update-grub

# Setup automatic disk unlock
if [ "$clevisautounlock" == "yes" ]
then
    source $toolpath/modules/setup_clevis_nbde.sh
fi

# Update initramfs
update-initramfs -u -k all

# Update GRUB configuration
update-grub

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
