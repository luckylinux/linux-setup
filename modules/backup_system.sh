#!/bin/bash

## !! THIS FILES IS EXECUTED **OUTSIDE** OF A CHROOT ENVIRONMENT !!

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d-%H%M%S")

# Load modules
modprobe spl
modprobe zfs

## BACKUP ROOT FILESYSTEM

# Import existing pool
mkdir -p $destination
chattr +i $destination
zpool import -R $destination -f $rootpool

# Wait a few seconds
sleep 5

# Snapshot all
zfs snapshot -r $rootpool@$snapshotname

# Send to remote server
# Normal Mode
#zfs send -Rv $rootpool@snapshotname | ssh root@backupserver zfs receive -F $backupdataset

# Readonly Mode
zfs send -Rv $rootpool@$snapshotname | ssh root@$backupserver zfs receive -o readonly=on -Fduv $backupdataset



## BACKUP BOOT
# Get mountpoint Info
#boot_info=$(chroot ${destination} /usr/bin/findmnt --fstab)

# Get only the SOURCE info (e.g. UUID=xxxx)
boot_source=$(chroot ${destination} /usr/bin/findmnt --fstab --target /boot --noheadings --output=SOURCE)

# Save Exit Code
boot_exit_code=$?

# If /boot is (already) a separate Partition
if [ -n "${boot_source}" ] && [ "${boot_exit_code}" -eq 0 ]
then
    # Mount Partition
    mount ${boot_source} ${destination}/boot
fi

# Backup Current Boot Partition Content
cd ${destination}/boot || exit
tar cvzf ${toolpath}/boot_$timestamp.tar.gz ./
cd ../ || exit



## BACKUP EFI
# Get all info
#efi_info=$(chroot ${destination} /usr/bin/findmnt --fstab)

# Get only the SOURCE info (e.g. UUID=xxxx)
efi_source=$(chroot ${destination} /usr/bin/findmnt --fstab --target /boot/efi --noheadings --output=SOURCE)

# Save Exit Code
efi_exit_code=$?

# If /boot/efi is (already) a separate Partition
if [ -n "${efi_source}" ] && [ "${efi_exit_code}" -eq 0 ]
then
    # Mount Partition
    mount ${efi_source} ${destination}/boot/efi
fi

# Backup Current EFI Partition Content
cd ${destination}/boot/efi || exit
tar cvzf ${toolpath}/efi_$timestamp.tar.gz ./
cd ../../ || exit

# Unmount /boot/efi
umount ${destination}/boot/efi

# Unmount /boot
umount ${destination}/boot

## UNMOUNT AND EXPORT POOL
zfs umount -a
zpool export -f ${rootpool}
