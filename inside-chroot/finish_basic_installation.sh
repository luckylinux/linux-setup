#!/bin/bash

# Load configuration
source ../config.sh

# Mount /boot
chattr +i /boot
mount /boot
mkdir -p /boot/efi
mkdir -p /boot/grub
chattr +i /boot/efi
mount /boot/efi

# Fix /etc/resolv.conf
rm -f /etc/resolv.conf
echo "nameserver $ns1" >> /etc/resolv.conf
echo "nameserver $ns2" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

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

# Install GRUB
if [ "$bootloadermode" == "BIOS" ]
then
    # BIOS
    apt-get nstall --yes grub-pc
else if [ "$bootloadermode" == "UEFI" ]
    # UEFI
    apt-get install --yes grub-efi-amd64
else
    # Not Supported
    echo "Error - bootloadermode <${bootloadermode}> is NOT supported. Aborting"
    exit 1
fi

# Ensure that NFS tools are mounted
mount /tools_nfs

# Setup GRUB Testing to ensure that ZFS bpool works correctly
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

# Enable importing bpool
tee /etc/systemd/system/zfs-import-bpool.service << EOF
[Unit]
DefaultDependencies=no
Before=zfs-import-scan.service
Before=zfs-import-cache.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/zpool import -N -o cachefile=none bpool
# Work-around to preserve zpool cache:
ExecStartPre=-/bin/mv /etc/zfs/zpool.cache /etc/zfs/preboot_zpool.cache
ExecStartPost=-/bin/mv /etc/zfs/preboot_zpool.cache /etc/zfs/zpool.cache

[Install]
WantedBy=zfs-import.target
EOF

systemctl enable zfs-import-bpool.service

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

# Update GRUB configuration
update-grub

# Install GRUB to MBR
if [ "$bootloadermode" == "BIOS" ]
then
    # BIOS
    grub-install "${device1}"
    grub-install "${device2}"
else
    # UEFI
    grub-install --target=x86_64-efi "${device1}"
    grub-install --target=x86_64-efi "${device2}"
    #grub-install --target=x86_64-efi --efi-directory=/boot/efi \
    #--bootloader-id=ubuntu --recheck --no-floppy
fi

# Update initramfs
update-initramfs -u -k all

# Update GRUB configuration
update-grub

# Disable grub fallback service
# Typically only needed for  mirror or raidz topology:
systemctl mask grub-initrd-fallback.service

# Verify that the ZFS module is installed
echo "!!! CHECK THAT THE ZFS MODULE IS INSTALLED !!!"
ls /boot/grub/*/zfs.mod

# Snapshot the initial installation
if [ "$bootfs" == "zfs" ]
then
    zfs snapshot -r bpool/BOOT/ubuntu@install
fi

if [ "$rootfs" == "zfs" ]
then
    zfs snapshot $rootpool/ROOT/$distribution@install
fi