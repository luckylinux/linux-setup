#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Import ZFS pool if not already mounted
if [ "${rootfs}" == "zfs" ]
then
        zpool import -f ${rootpool} -o readonly=$readonly -R "${destination}"
        zfs mount ${rootpool}/ROOT/$distribution
        zfs set devices=off ${rootpool}

        # Get list of datasets
        datasets=$(zfs list -H -o name | grep -i "${rootpool}" | xargs -n1)

        while IFS= read -r dataset; do
            # Check if indeed we should mount it
            tomount=$(zfs get canmount -H -o value ${dataset})

            if [[ "${tomount}" == "on" ]]
            then
                zfs mount ${dataset}
            fi
        done <<< "${dataset}s"
else
    if [ "${numdisks_total}" -eq 1 ]
    then
        mount ${devices[0]}-part${root_num} "${destination}"
    else
        mount /dev/${mdadm_root_device} "${destination}"
    fi
fi

# Create Folders for boot and efi
mkdir -p ${destination}/boot

# Import ZFS pool if not already mounted
if [ "${bootfs}" == "zfs" ]
then
        zpool import -f ${bootpool} -o readonly=$readonly -R "${destination}"
        zfs mount ${bootpool}/BOOT/$distribution

        # Get list of datasets
        datasets=$(zfs list -H -o name | grep -i "${bootpool}" | xargs -n1)

        while IFS= read -r dataset; do
            # Check if indeed we should mount it
            tomount=$(zfs get canmount -H -o value ${dataset})

            if [[ "${tomount}" == "on" ]]
            then
                zfs mount ${dataset}
            fi
        done <<< "${dataset}s"
else
    if [ "${numdisks_total}" -eq 1 ]
    then
        mount ${devices[0]}-part${boot_num} "${destination}/boot"
    else
        mount /dev/${mdadm_boot_device} "${destination}/boot"
    fi
fi

# Create Folder for /boot/efi
mkdir -p ${destination}/boot/efi

# Mount efi Filesystems
for disk in "${disks[@]}"
do
    # Get EFI Mount Path
    efi_mount_path=$(get_efi_mount_path "${disk}")

    # Get UUID of Single Disk Partition
    UUID=$(blkid -s UUID -o value "/dev/disk/by-id/${disk}-part${efi_num}")

    # Mount Filesystem
    mount "/dev/disk/by-id/${disk}-part${efi_num}" "${destination}${efi_mount_path}"
done
