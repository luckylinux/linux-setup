#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Update APT Lists
update_lists

# Install clevis on the system and add clevis to the initramfs
install_packages_unattended clevis clevis-luks clevis-initramfs cryptsetup-initramfs

# Ask for password
read -s -p "Enter encryption password: " password

# For each Device
for device in "${devices[@]}"
do
    # Existing CLEVIS Tang Slots
    mapfile existing_clevis_tang_keyslots < <(clevis luks list -d $device-part${root_num} | grep -E "[0-9]+: tang" | sed -E "s|([0-9]+): tang.*|\1|g")

    # Initialize Counter
    counter=1

    # For each keyserver found
    for existing_clevis_tang_keyslot in "${existing_clevis_tang_keyslots[@]}"
    do
        # Unbind device from the TANG server via CLEVIS
        echo "Remove Keyserver <$keyserver> from $device LUKS Header"
        echo $password | clevis luks unbind -d ${device}-part${root_num} -s ${existing_clevis_tang_keyslot}

        # Increment counter
        counter=$((counter+1))
     done
done

# Clear password from memory
unset $password

# Update initramfs
regenerate_initrd

# Get information
for disk in "${disks[@]}"
do
    cryptsetup luksDump /dev/disk/by-id/${disk}-part${root_num}
    clevis luks list -d /dev/disk/by-id/${disk}-part${root_num}
done