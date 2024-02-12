#!/bin/bash

# Load files in config/ folder
source config/*.sh

# Other Configuration
# Define disks
disk1="ata-CT500MX500SSD1_1835E14E9C46"
disk2="ata-CT500MX500SSD1_2025E2AE5EF0"

# Full path
device1="/dev/disk/by-id/${disk1}"
device2="/dev/disk/by-id/${disk2}"

# Put disks into array
disks=()
disks+=("$disk1")
disks+=("$disk2")

# Put devices into array
devices=()
devices+=("$device1")
devices+=("$device2")

# Get number of disks
numdisks=${#disks[@]}
numdevices=${#devices[@]}

# Suppress output
n="/dev/null"

# Backup Server
backupserver="myipadddress"
backupdataset="zdata/BACKUP/$name"

# Backup Snapshot Name
timestamp=$(date +%Y%m%d)
snapshotname="${timestamp}"

# Define distribution
distribution="debian" # "debian" or "ubuntu"

# Define distribution release
release="bookworm" # "bullseye", "bookworm", "testing"

# Define Debian archive
source="http://ftp.dk.debian.org/debian/"

# Exclude packages when running debootstrap
excludepackages="netplan.io,snapd"

# Define mountpoint
destination="/mnt/$distribution"

# Define hostname
hostname="pveX"

# Define domainname
domainname="mydomain.tld"

# Define ip address
ipconfiguration="static"   # "static" or "dhcp"
ipaddress="myipadddress"   # Only relevant for "static"
subnetmask="255.255.240.0" # Only relevant for "static"
defgateway="192.168.1.1"   # Only relevant for "static"

# Nameservers
ns1="192.168.1.3"
ns2="192.168.1.4"

# Declare disk labels
labels=("DISK1" "DISK2")

# Filesystem Choices
bootfs="zfs" # "ext4", "zfs" or "none" to skip altogether (leaves partition formatted but NOT mounted / empty)
rootfs="zfs" # "ext4" or "zfs"

# RAID Choices
efiraid="mdadm" # "mdadm"
bootraid="auto" # "auto" ("zfs" if bootfs="zfs", else "mdadm" if numdisks > 1)
rootraid="auto" # "auto" ("zfs" if rootfs="zfs", else "mdadm" if numdisks > 1)

# Encryption
encryptrootfs="luks" # "luks" or "no"

# Bootloader Choice
bootloader="grub" # "grub" or "zbm"

# Clevis Automatic Unlock
clevisautounlock="yes" # "yes" or "no"

# Define partition sizes
# You can find disk size with the following command
# parted -s /dev/sdX unit MiB print free | grep MiB | head -n1

# Disk size could be automatically be extracted with
# parted -s /dev/sdX unit MiB print free | grep MiB | head -n1 | sed -En "s/.*: (.*)MiB/\1/p"
# or
# parted -s /dev/sdX unit MiB print free | sed -En "s/Disk \/dev\/sdX: (.*)MiB/\1/p"

# Layout is always
#    - partition #1: bios grub
#    - partition #2: fat32 for EFI
#    - partition #3: /boot
#    - partition #4: /

disk_size=476940                                                # MiB
bios_size=64                                                    # MiB
efi_size=1024                                                   # MiB
boot_size=2048                                                  # MiB
swap_size=$((0*1000))                                           # MiB
margin_size=512                                                 # MiB
root_size=$((disk_size-bios_size-efi_size-boot_size-swap_size-margin_size))      # MiB

# Pool settings
# Ashift=13 can lead to some overhead
ashift=12
rootpool="rpool"
bootpool="bpool"

# CLEVIS/TANG Automated LUKS unlocking
keyservers=("192.168.1.15" "192.168.1.16" "192.168.1.17" "192.168.1.18")

# Mode to be used ("BIOS" / "UEFI")
# Only relevant for grub installation
# (both partition schemes are created in order to facilitate change - if needed)
bootloadermode="UEFI"