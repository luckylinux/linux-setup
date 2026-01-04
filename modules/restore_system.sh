#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d-%H%M%S")

# Load modules
modprobe spl
modprobe zfs

# Wait a few seconds
sleep 5

# Restore ZFS Snapshot
#ssh root@$backupserver zfs send -Rv $backupdataset@$snapshotname | zfs receive -Fduv ${rootpool}
ssh root@${backupserver} zfs send -Rv ${backupdataset}@${snapshotname} | zfs receive -o mountpoint=/ -F ${rootpool}

# Restore ZFS mountpoints
source "${toolpath}/ad-hoc/restore_zfs_mountpoints.sh"

# Import ZFS pool if not already mounted
if [ "${rootfs}" == "zfs" ]
then
    # Mount Filesystem
    zfs mount ${rootpool}/ROOT/${distribution}
fi

# Make sure that /boot is empty and properly set the Immutable bit before any Filesystem is mounted there
mkdir "${destination}/_boot_local_${timestamp}"
umount ${destination}/boot
mv ${destination}/boot/* ${destination}/_boot_local_${timestamp}/
chattr +i ${destination}/boot
mount /dev/${mdadm_boot_device} ${destination}/boot

# Create /boot/efi EFI Folder and make sure it can be modified
mkdir -p ${destination}/boot/efi

# Allow direct writing to the Folder
chattr -i ${destination}/boot/efi

# Create a Subfolder for each Disk ESP/EFI Partition
for disk in "${disks[@]}"
do
    # Get EFI Mount Path
    efi_mount_path=$(get_efi_mount_path "${disk}")

    # Echo
    echo "Setting up Mountpoint ${efi_mount_path} at ${destination}/${efi_mount_path}"

    # Create Mountpoint Folder and make it immutable
    mkdir -p "${destination}/${efi_mount_path}"
    chattr +i "${destination}/${efi_mount_path}"

    # Mount EFI Mountpoints
    mount "/dev/disk/by-id/${disk}-part${efi_num}" "${destination}/${efi_mount_path}"
done

# Move Files that were in /_boot_local_${timestamp} to the newly created /boot Partition
mv ${destination}/_boot_local_${timestamp}/* ${destination}/boot/
rmdir ${destination}/_boot_local_${timestamp}

# Restore /boot Archive
boot_archive=""

while [ -z "${boot_archive}" ] | [ ! -f "${toolpath}/${boot_archive}" ]
do
    echo "Available Archives for /boot Restore"

    mapfile -t boot_located_archives < <( find "${toolpath}/" -maxdepth 1 -iname "boot_*.tar.gz" )
    for boot_located_archive in "${boot_located_archives[@]}"
    do
        # Get Archive Filename
        boot_located_archive_filename=$(basename "${boot_located_archive}")

        # Get File Size
        boot_located_archive_filesize_megabytes=$(stat "${toolpath}/${boot_located_archive_filename}" --format "%s" | echo "scale=1; file_size_bytes=$(cat /dev/stdin); file_size_bytes/1024/1024;" | bc)

        # Echo
        echo -e "\t- ${boot_located_archive_filename} (${boot_located_archive_filesize_megabytes} MB) located at ${toolpath}/${boot_located_archive_filename}"
    done


    read -p "Please select the /boot Archive to restore Files from: " boot_archive

    if [[ -z "${boot_archive}" ]]
    then
        echo "ERROR: Input was Empty."
    elif [[ ! -f "${toolpath}/${boot_archive}" ]]
    then
        echo "ERROR: Boot Archive <${boot_archive}> could not be found at ${toolpath}/${boot_archive} !"
    fi

    # Add some Vertical Spacing
    echo -e "\n"
done

# Extract /boot Archive
tar xvf "${toolpath}/${boot_archive}" -C "${destination}/boot"

# Restore EFI Archive
# To be implemented
# ...

# Move /boot files to dedicated BOOT pool
#zfs umount ${bootpool}/BOOT/$distribution
#zfs mount ${rootpool}/ROOT/$distribution
#mv $destination/boot $destination/boot_old
#zfs mount ${bootpool}/BOOT/$distribution
#cp -r $destination/boot_old/* destination/boot/
#sync
