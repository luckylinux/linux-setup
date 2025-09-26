#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Ask for User Input
ls -l /dev/disk/by-id/ | grep -Ev "part[0-9]+|wwn|dm-name|dm-uuid|md-uuid"

old_disk="INVALID"
while [ ! -b "/dev/disk/by-id/${old_disk}" ]
do
    read -p "Enter old Disk Name: " old_disk
done

new_disk="INVALID"
while [ ! -b "/dev/disk/by-id/${new_disk}" ]
do
    read -p "Enter new Disk Name: " new_disk
done

# Export Configuration
export devices=("/dev/disks/by-id/${new_disk}")
real_disk=$(readlink --canonicalize-missing "/dev/disks/by-id/${new_disk}"
export disks=$(real_disk))

# Display what is going to be performed
echo "This Script will migrate Data from /dev/disk/by-id/${old_disk} to /dev/disk/by-id/${new_disk}"

# Prompt for Confirmation
read -p "Are you sure you want to proceed ? [yes / no]: " are_you_sure

if [[ "${are_you_sure}" != "yes" ]]
then
    # Abort
    echo "Abort !"
    exit 1
fi

# Get all Pools
all_pools=$(zpool status -j | jq -r ".pools | to_entries | .[].key")

# Initialize Found Status
found_old_device="no"

# Loop over each Pool
for pool in "${all_pools[@]}"
do
    # Get Devices
    all_devices=$(zpool status -j | jq -r ".pools.${pool}.vdevs.${pool}.vdevs | to_entries | .[].value.vdevs | to_entries | .[].key")

    for device in "${all_devices[@]}"
    do
        device_check=$(echo "${device}" | grep -q "${old_disk}")
        device_status_code=$?

        if [ ${device_status_code} -eq 0 ]
        then
            found_old_device="yes"
        fi
    done
done

# Check if old Disk is Member of Pool
if [[ "${found_old_device}" != "yes" ]]
then
    echo "Old Disk is NOT Member of Pool. Aborting !"
    exit 2
fi

# Init Partitioning for new Disk
source ${toolpath}/modules/init_partitioning.sh

# Setup new Disk
source ${toolpath}/modules/setup_partitions.sh



# Copy Partition Table
# sgdisk /dev/disk/by-id/${old_disk} -R /dev/disk/by-id/${new_disk}

# Expand Partition Table

# Randomize GUID on the new Disk
# sgdisk -G /dev/disk/by-id/${new_disk}

# Format EFI Partition
# mkfs.vfat -F 32 /dev/disk/by-id/${new_disk}-part${efi_num}

# Update EFI
# sed -Ei "s|${old_disk}|${new_disk}|" /etc/fstab

# Update BOOT Configuration for MDADM
# sed -Ei "s|${old_disk}|${new_disk}|" /etc/mdadm/boot.mdadm

# Perform MDADM Device Replacement
mdadm --manage /dev/${mdadm_boot_device} --fail /dev/disk/by-id/${old_disk}-part${boot_num}
mdadm --manage /dev/${mdadm_boot_device} --remove /dev/disk/by-id/${old_disk}-part${boot_num}
mdadm --manage /dev/${mdadm_boot_device} --add /dev/disk/by-id/${new_disk}-part${boot_num}

# Update Root Device Configuration in /etc/crypttab
sed -Ei "s|${old_disk}|${new_disk}|" /etc/crypttab

# Perform Pool Device Replacement
zpool replace ${rootpool} ${old_device} ${new_device}

# Update Cachefile
# ...
