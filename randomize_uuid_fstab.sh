#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Parse Action
action="$1"

if [[ -z "${action}" ]]
then
    echo "ERROR: you must specify an Action. Choose between: [update-fstab,update-devices]"
fi

# Generate Timestamp
backup_timestamp=$(date +"%Y%m%d%H%M%S")

# Install Requirements
apt-get install uuid-runtime mtools

# Unmount System to have a "Clean Start"
source ${toolpath}/umount_everything.sh
source ${toolpath}/umount_everything.sh

# Mount System Chroot
source ${toolpath}/modules/mount_system.sh

if ! mountpoint -q ${destination}
then
    echo "ERROR: ${destination} cannot be mounted. Aborting !"
fi

# Backup current /etc/fstab
cp ${destination}/etc/fstab ${destination}/etc/fstab.backup.${backup_timestamp}

# Echo
echo "Reading Lines from ${destination}/etc/fstab"

# Get Lines in /etc/fstab starting with UUID=
mapfile lines < <(cat ${destination}/etc/fstab | grep -E "^UUID=")

# Echo
echo "Unmounting Everything from Target Mountpoint"

# Unmount System Chroot in order to be able to run tune2fs and e2fsck
source ${toolpath}/umount_everything.sh
source ${toolpath}/umount_everything.sh

# Initialize Arrays
old_lines=()
new_lines=()

# Echo
echo -e "Performing Step #1"

# Loop over FSTAB Lines
for line in "${lines[@]}"
do
    # Clean line
    line=$(echo "${line}" | head -n1)

    # Echo
    echo -e "\tStore Cleaned Line ${line} from /etc/fstab in Array"

    # Store in old_lines
    old_lines+=("${line}")
done

# Counter the Number of Items
number_lines="${#old_lines[@]}"

# Echo
echo -e "Performing Step #2"

# Change Partitions PARTUUID / Filesystems UUID
for index_line in $(seq 0 $((number_lines-1)))
do
    # Extract Values
    old_line=${old_lines[${index_line}]}

    if [[ "${action}" == "update-devices" ]]
    then
        # Use the existing Line in /etc/fstab
        new_line="${old_line}"
    fi

    # Extract Filesystem Part
    filesystem=$(echo "${old_line}" | awk '{print $1}')
    targetmount=$(echo "${old_line}" | awk '{print $2}')

    # Echo
    echo -e "\t[$((index_line+1))]"
    echo -e "\t\tProcessing Line: ${old_line}"
    echo -e "\t\t(${filesystem} -> ${targetmount})"

    # Get current UUID
    current_uuid=$(echo "${filesystem}" | sed -E "s|UUID=([0-9a-zA-Z-]+)|\1|")

    # Get Device link from /dev/disk/by-uuid/<current_uuid>
    device_uuid_path="/dev/disk/by-uuid/${current_uuid}"

    # Check if Device actually exists and is a Symlink
    if [[ -L "${device_uuid_path}" ]]
    then
        # Get Device /dev/sdX by reading where the Link Points to
        device_real_path=$(readlink --canonicalize-missing "${device_uuid_path}")

        # Get Device Name
        device_name=$(basename "${device_real_path}" | sed -E "s|^([a-zA-Z]+)([0-9]+)$|\1|")

        # Get Device Partition Number
        partition_number=$(basename "${device_real_path}" | sed -E "s|^([a-zA-Z]+)([0-9]+)$|\2|")

        # Get Current PARTUUID
        current_partuuid=$(udevadm info --property=ID_PART_ENTRY_UUID --query=property "/dev/${device_name}${partition_number}" | sed -E "s|ID_PART_ENTRY_UUID=([0-9a-zA-Z-]+)|\1|")

        if [[ "${action}" == "update-fstab" ]]
        then
            # Generate new UUID
            new_uuid=$(uuidgen)

            # Generte new PARTUUID
            new_partuuid=$(uuidgen)
        else
            # Use old Values
            new_uuid="${current_uuid}"
            new_partuuid="${current_partuuid}"
        fi

        # Get Filesystem Type
        # ** does NOT work inside Chroot since lsblk relies on udev which relies on systemd which does NOT work inside Chroots **
        # filesystem_type=$(lsblk -o FSTYPE --raw --noheadings --nodeps "/dev/${device_name}${partition_number}")

        # Get Filesystem Type
        # filesystem_type=$(parted -s "/dev/${device_name}${partition_number}" print --json | grep -Ei '"filesystem": ".*"' | sed -E 's|^\s?*"filesystem": "([a-zA-Z0-9]+)"$|\1|')
        filesystem_type=$(parted -s "/dev/${device_name}${partition_number}" print --machine | tail -n1 | cut -d: -f5)

        # Get Current PARTUUID
        # This returns an empty String :/
        # current_partuuid=$(lsblk -o PARTUUID --raw --noheadings --nodeps "/dev/${device_name}${partition_number}")

        # Echo
        echo -e "\t\tProcessing Partition Number ${partition_number} of Device ${device_name}"

        if [[ "${filesystem_type}" == ext* ]]
        then
            # Must perform a fresh Check of the Filesystem in order to use tune2fs
            e2fsck -f "${device_real_path}"

            if [[ "${current_uuid}" != "${new_uuid}" ]]
            then
                # Use tune2fs for FS UUID
                tune2fs -U "${new_uuid}" "${device_real_path}"
            fi

            if [[ "${current_partuuid}" != "${new_partuuid}" ]]
            then
                # Use sgdisk for PARTUUID
                sgdisk -u "${partition_number}:${new_partuuid}" "/dev/${device_name}"
            fi
        elif [[ "${filesystem_type}" == "fat32" ]]
        then
            # Need to use a shorter UUID in the Form of 4 Characters + "-" + 4 Characters (all uppercase)
            part_one=$(echo "${new_uuid}" | cut -c 1-4)
            part_two=$(echo "${new_uuid}" | cut -c 5-8)
            new_uuid="${part_one}${part_two}"
            new_uuid=${new_uuid^^}

            if [[ "${current_uuid}" != "${new_uuid}" ]]
            then
                # Use mlabel for FS UUID
                mlabel -N "${new_uuid}" -i  "${device_real_path}" ::
            fi

            if [[ "${current_partuuid}" != "${new_partuuid}" ]]
            then
                # Use sgdisk for PARTUUID
                sgdisk -u "${partition_number}:${new_partuuid}" "/dev/${device_name}"
            fi
        else
            echo "ERROR: ${filesystem_type} is NOT supported. Aborting !"
            exit 9
        fi

        if [[ "${action}" == "update-fstab" ]]
        then
            # Echo
            echo -e "\t\tDefine Change in UUID from ${current_uuid} to ${new_uuid} for Mount Point ${targetmount}"

            # New /etc/fstab Line
            new_line=$(echo "${old_line}" | sed -E "s|^UUID=([0-9a-zA-Z-]+)(\s.*)$|UUID=${new_uuid}\2|")
        fi

        # Store in new_lines
        new_lines+=("${new_line}")
    else
        # Error
        echo "ERROR: Device ${device_uuid_path} does NOT exist. Did you already run this Script and must reboot in order for the Kernel to be notified of the Changes ?"
        echo "ABORTING !"
        exit 6
    fi

    # Not really needed anymore
    # new_line=${new_lines[${index_line}]}
done

# Echo
echo "Mount Target System to Target Mountpoint ${destination}"

# Mount System Chroot
source ${toolpath}/modules/mount_system.sh
source ${toolpath}/modules/mount_bind.sh

# Echo
echo -e "Performing Step #3"

# Perform Replacement
for index_line in $(seq 0 $((number_lines-1)))
do
    # Extract Values
    old_line=${old_lines[${index_line}]}
    new_line=${new_lines[${index_line}]}

    # Echo
    echo -e "\t[$((index_line+1))]"
    echo -e "\t\tChanging ${destination}/etc/fstab Line"
    echo -e "\t\t\t- Old: ${old_line}"
    echo -e "\t\t\t- New: ${new_line}"

    if [[ "${old_line}" != "${new_line}" ]]
    then
        # Perform Replacement
        sed -Ei "s|${old_line}|${updated_line}|" ${destination}/etc/fstab
    fi
done

# Copy tool to chroot folder
source ${toolpath}/modules/copy_tool_to_chroot.sh

# Run inside-chroot/install_bootloader.sh inside chroot
chroot ${destination} /bin/bash -c "/tools_install/${timestamp}/inside-chroot/install_bootloader.sh"

# Update Grub Configuration
#if [[ $(command -v update-grub) ]]
#then
#    update-grub
#elif [[ $(command -v grub2-mkconfig) ]]
#then
#    grub2-mkconfig -o /boot/grub2/grub.cfg
#fi

# Update Initramfs
#if [[ $(command -v update-initramfs) ]]
#then
#    update-initramfs -k all -u
#elif [[ $(command -v dracut) ]]
#then
#    dracut --regenerate-all --force
#fi

# Echo
echo "Unmounting Everything from Target Mountpoint"

# Unmount Chroot again
source ${toolpath}/umount_everything.sh
source ${toolpath}/umount_everything.sh
