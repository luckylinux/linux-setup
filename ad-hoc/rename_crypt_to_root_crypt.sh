#!/bin/bash

# Abort on errors
set -e

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Standalone EFI/ESP Setup
for disk in "${disks[@]}"
do
    # Define Device
    device="/dev/disk/by-id/${disk}-part${root_num}"

    # Device old Crypt Device Name
    crypt_device_old="${disk}_crypt"

    # Device new Crypt Device Name
    crypt_device_new="${disk}_root_crypt"

    # Replace in /etc/crypttab
    sed -Ei "s|${crypt_device_old}|${crypt_device_new}|g" /etc/crypttab

    # Offline LUKS Device from Pool
    zpool offline "${root_pool}" "${crypt_device_old}"

    # Close LUKS Device
    cryptsetup luksClose "${crypt_device_old}"

    # Open LUKS Device with the new Name
    clevis luks unlock -d "${device}" -n "${crypt_device_new}"

    # Update Pool Configuration
    zpool set path="/dev/mapper/${crypt_device_new}" "${root_pool}" "${crypt_device_old}"

    # Online Device
    zpool online "${root_pool}" "${crypt_device_new}"

    # Clear Pool Errors
    zpool clear "${root_pool}"

    # Reopen ZFS Pool
    zpool reopen "${root_pool}"
done

# (Re)generate /etc/zfs/zpool.cache
rm -f cachefile=/etc/zfs/zpool.cache
zpool set cachefile=/etc/zfs/zpool.cache "${root_pool}"

# Regenerate InitramFS
update-initramfs -k all -u

# Update GRUB Configuration
update-grub

# Regenerate InitramFS
update-initramfs -k all -u

# Update GRUB Configuration
update-grub

