#!/bin/bash

# Do NOT Abort on errors
#set -e

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Mount Current /boot partition
mount /boot

# Generate Timestamp for backup archive
timestamp_long=$(date +"%Y%m%d-%H%M%S")

# Backup Current /boot partition content
cd /boot/efi
tar cvzf /boot_efi_${timestamp_long}.tar.gz ./
cd ..

# Determine current UUID of /dev/${mdadm_efi_device} in order to disable it in /etc/fstab
# This should prevent SystemD from remounting it immediately
mdadm_efi_uuid=$(blkid -s UUID -o value /dev/${mdadm_efi_device})

sed -Ei "s|^UUID=${mdadm_efi_uuid}(.+)|# UUID=${mdadm_efi_device}\1|g"

systemctl daemon-reload

# Unmount /boot/efi
umount /boot/efi

# Stop /dev/md{efi_num}
mdadm --stop /dev/${mdadm_efi_device}
mdadm --stop /dev/${mdadm_efi_device}

# Standalone EFI/ESP Setup
for disk in "${disks[@]}"
do
    # Define Device
    device="/dev/disk/by-id/${disk}-part${efi_num}"

    # Mark RAID Member Device as failed
    mdadm /dev/${mdadm_efi_device} --fail "${device}"

    # Remove RAID Member Device from Array
    mdadm /dev/${mdadm_efi_device} --remove "${device}"

    # Wait a bit
    sleep 1

    # Clear MDADM Superblock
    mdadm --zero-superblock --force "${device}"
done

# Move Configuration File to /etc/mdadm/efi.disabled
if [[ -f /etc/mdadm/efi.mdadm ]]
then
    # Move File (ask User if this would result in a File being overwritten)
    mv --interactive /etc/mdadm/efi.mdadm /etc/mdadm/efi.disabled
fi

if [[ -f /etc/mdadm/efi.mdadm.disabled ]]
then
    # Comment Lines in order to prevent erroneous remounts
    sed -Ei "s|^member_devices\+=\(\s?\"([a-zA-Z0-9/_-]+)\"\s?\)|#member_devices=( \"\1\" )|g" /etc/mdadm/efi.mdadm.disabled
fi

if [[ -f /etc/mdadm/efi.disabled ]]
then
    # Comment Lines in order to prevent erroneous remounts
    sed -Ei "s|^member_devices\+=\(\s?\"([a-zA-Z0-9/_-]+)\"\s?\)|#member_devices=( \"\1\" )|g" /etc/mdadm/efi.disabled
fi

# Execute EFI Device(s) Setup
source ${toolpath}/modules/setup_efi_partition.sh

# Create /boot/efi Folder
mkdir -p /boot/efi

# Allow direct writing to the Folder
chattr -i /boot/efi

# Create a Subfolder for each Disk ESP/EFI Partition
for disk in "${disks[@]}"
do
    # Get EFI Mount Path
    efi_mount_path=$(get_efi_mount_path "${disk}")

    mkdir -p "${efi_mount_path}"
    chattr +i "${efi_mount_path}"
done

# Configure FSTAB
source ${toolpath}/modules/configure_efi_partition.sh

# Mount the newly created ESP/EFI Devices
for disk in "${disks[@]}"
do
    # Get EFI Mount Path
    efi_mount_path=$(get_efi_mount_path "${disk}")

    mount "/boot/efi/${disk}"
done

# Force Bootloader Installation from Live System
export force_bootloader_installation_from_running_system="yes"
source ${toolpath}/inside-chroot/install_bootloader.sh

# Update Grub
update-grub

# Update Initramfs
update-initramfs -k all -u

# Update Grub
update-grub
