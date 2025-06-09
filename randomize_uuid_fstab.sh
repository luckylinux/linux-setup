#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Parse Action
action="$1"

# Define Devices Base Folder
devices_basepath="${toolpath}/data/devices"

# Abort if Action not set
if [[ -z "${action}" ]]
then
    echo "ERROR: you must specify an Action. Choose between: [generate-new,update-fstab,update-devices]"
    exit 1
fi

# Display Warning
echo -e "**WARNING**"
echo -e "This Script will change the UUID and PARTUUID for the Following Devices"
for device in "${devices[@]}"
do
    echo -e "\t- ${device}"
done

read -p "Are you sure you want to proceed [yes/no]: " keep_going

if [[ "${keep_going}" != "yes" ]]
then
    echo -e "ABORTING Execution"
    exit 2
fi

# Generate Timestamp
backup_timestamp=$(date +"%Y%m%d%H%M%S")

# Install Requirements
apt-get install uuid-runtime mtools

# Unmount System to have a "Clean Start"
source "${toolpath}/umount_everything.sh"

# Mount System Chroot
source "${toolpath}/modules/mount_system.sh"

# Abort if / of Chroot couldn't be mounted
if ! mountpoint -q ${destination}
then
    echo "ERROR: ${destination} cannot be mounted. Aborting !"
    exit 3
fi

# Backup current /etc/fstab
cp "${destination}/etc/fstab" "${destination}/etc/fstab.backup.${backup_timestamp}"

# Echo
echo "Reading Lines from ${destination}/etc/fstab"

# Get Lines in /etc/fstab starting with UUID=
mapfile fstab_lines < <(cat ${destination}/etc/fstab | grep -E "^UUID=")

# Echo
echo "Unmounting Everything from Target Mountpoint"

# Unmount System Chroot in order to be able to run tune2fs and e2fsck
source "${toolpath}/umount_everything.sh"

# Echo
echo -e "Performing Step #1 - Reading /etc/fstab Contents"

# Initialize Arrays
old_fstab_lines=()
new_fstab_lines=()

# Loop over FSTAB Lines
for fstab_line in "${fstab_lines[@]}"
do
    # Clean line
    fstab_line=$(echo "${fstab_line}" | head -n1)

    # Echo
    echo -e "\tStore Cleaned Line ${fstab_line} from /etc/fstab in Array"

    # Store in old_fstab_lines
    old_fstab_lines+=("${fstab_line}")
done

# Counter the Number of Items in /etc/fstab
fstab_number_lines="${#old_fstab_lines[@]}"

# Echo
echo -e "Performing Step #2 - Updating Devices UUID/PARTUUID"

# Loop over Devices
for device in "${devices[@]}"
do
    # Get only the last Part of the Path
    device_id=$(basename "${device}")

    # Create Folder Structure
    mkdir -p "${devices_basepath}/${device_id}"

    # Get Device /dev/sdX by reading where the Link Points to
    device_real_path=$(readlink --canonicalize-missing "${device}")

    # Get Device Name
    device_name=$(basename "${device_real_path}" | sed -E "s|^([a-zA-Z]+)([0-9]+)$|\1|")

    # Get List of Partitions
    mapfile -t partition_numbers < <( find /dev -iwholename "${device_real_path}[0-9]"* | sed -E "s|${device_real_path}||g" | sort --human )

    # Loop over Partitions
    for partition_number in "${partition_numbers[@]}"
    do
        # Echo
        echo -e "\t\tProcessing Partition Number ${partition_number} of Device ${device_name}"

        # Get current UUID
        current_device_uuid=$(udevadm info --property=ID_FS_UUID --query=property "/dev/${device_name}${partition_number}" | sed -E "s|ID_FS_UUID=([0-9a-zA-Z-]+)|\1|")

        # Get Current PARTUUID
        # This returns an empty String - lsblk / udev / systemd NOT working inside Chroot
        # current_device_partuuid=$(lsblk -o PARTUUID --raw --noheadings --nodeps "/dev/${device_name}${partition_number}")        

        # Get Current PARTUUID
        current_device_partuuid=$(udevadm info --property=ID_PART_ENTRY_UUID --query=property "/dev/${device_name}${partition_number}" | sed -E "s|ID_PART_ENTRY_UUID=([0-9a-zA-Z-]+)|\1|")

        # Get Device link from /dev/disk/by-uuid/<current_device_uuid>
        device_uuid_path="/dev/disk/by-uuid/${current_device_uuid}"

        # Get Device link from /dev/disk/by-partuuid/<current_device_partuuid>
        device_partuuid_path="/dev/disk/by-uuid/${current_device_partuuid}"

        # Get Partition Flags
        partition_flags=$(parted -s "/dev/${device_name}" print --machine 2> /dev/null | grep -E "^${partition_number}" | cut -d: -f7)

        # Get Filesystem Type
        # ** does NOT work inside Chroot since lsblk relies on udev which relies on systemd which does NOT work inside Chroots **
        # filesystem_type=$(lsblk -o FSTYPE --raw --noheadings --nodeps "/dev/${device_name}${partition_number}")

        # Get Filesystem Type
        # filesystem_type=$(parted -s "/dev/${device_name}${partition_number}" print --json | grep -Ei '"filesystem": ".*"' | sed -E 's|^\s?*"filesystem": "([a-zA-Z0-9]+)"$|\1|')
        filesystem_type=$(parted -s "/dev/${device_name}${partition_number}" print --machine | tail -n1 | cut -d: -f5)

        # Create Folder Structure
        mkdir -p "${devices_basepath}/${device_id}/${partition_number}"

        # Save Current UUID if not done already
        if [[ ! -f "${devices_basepath}/${device_id}/${partition_number}/old.uuid" ]]
        then
            echo "${current_device_uuid}" > "${devices_basepath}/${device_id}/${partition_number}/old.uuid"
        fi

        # Save Current PARTUUID if not done already
        if [[ ! -f "${devices_basepath}/${device_id}/${partition_number}/old.partuuid" ]]
        then
            echo "${current_device_partuuid}" > "${devices_basepath}/${device_id}/${partition_number}/old.partuuid"
        fi                

        # Determine new UUID
        if [[ ! -f "${devices_basepath}/${device_id}/${partition_number}/new.uuid" ]]
        then
            # Generate new UUID
            new_uuid=$(uuidgen)

            # Shorten it in case of FAT32 to 8 Characters
            if [[ "${filesystem_type}" == "fat32" ]]
            then
                # Need to use a shorter UUID in the Form of 8 Characters
                new_uuid=$(echo "${new_uuid}" | cut -c 1-8)

                # Transform into all Uppercase
                new_uuid=${new_uuid^^}
            fi

            # Write to File
            echo "${new_uuid}" > "${devices_basepath}/${device_id}/${partition_number}/new.uuid"
        else
            # Load new UUID from File
            new_uuid=$(cat "${devices_basepath}/${device_id}/${partition_number}/new.uuid")
        fi

        # Determine new PARTUUID
        if [[ ! -f "${devices_basepath}/${device_id}/${partition_number}/new.partuuid" ]]
        then
            # Generte new PARTUUID
            new_partuuid=$(uuidgen)

            # Write to File
            echo "${new_partuuid}" > "${devices_basepath}/${device_id}/${partition_number}/new.partuuid"
        else
            # Load new UUID from File
            new_partuuid=$(cat "${devices_basepath}/${device_id}/${partition_number}/new.partuuid")
        fi


        # Exclude the BIOS_GRUB Partition
        if [[ "${partition_flags}" == "bios_grub"* ]]
        then
            echo "INFO: Skip Partition ${partition_number} for Device ${device_real_path} since it's marked with bios_grub Flag"
        else
            # Check if Device & Partition actually exists and is a Symlink
            if [[ -L "${device_uuid_path}" ]]
            then
                # Update UUID
                if [[ "${filesystem_type}" == ext* ]]
                then
                    # Must perform a fresh Check of the Filesystem in order to use tune2fs
                    e2fsck -f "/dev/${device_name}${partition_number}"

                    if [[ "${current_device_uuid}" != "${new_uuid}" ]]
                    then
                        # Use tune2fs for FS UUID
                        tune2fs -U "${new_uuid}" "/dev/${device_name}${partition_number}"
                    fi
                elif [[ "${filesystem_type}" == "fat32" ]]
                then
                    if [[ "${current_device_uuid}" != "${new_uuid}" ]]
                    then
                        # Use mlabel for FS UUID
                        mlabel -N "${new_uuid}" -i  "/dev/${device_name}${partition_number}" ::
                    fi
                else
                    echo "ERROR: ${filesystem_type} is NOT supported. Aborting !"
                    exit 9
                fi

                # Update PARTUUID
                if [[ "${current_device_partuuid}" != "${new_partuuid}" ]]
                then
                    # Use sgdisk for PARTUUID
                    sgdisk -u "${partition_number}:${new_partuuid}" "/dev/${device_name}"
                fi

            else
                # Error
                echo "ERROR: Device ${device_uuid_path} does NOT exist. Did you already run this Script and must reboot in order for the Kernel to be notified of the Changes ?"
                echo "ABORTING !"
                exit 6
            fi
        fi
    done
done


# Echo
echo "Mount Target System to Target Mountpoint ${destination}"

# Mount System Chroot
source "${toolpath}/modules/mount_system.sh"
source "${toolpath}/modules/mount_bind.sh"

# Echo
echo -e "Performing Step #3 - Update /etc/fstab"

# Loop over FSTAB Entries
for index_fstab_line in $(seq 0 $((fstab_number_lines-1)))
do
    # Extract Values
    old_fstab_line=${old_fstab_lines[${index_fstab_line}]}

    # Extract Filesystem Part
    filesystem=$(echo "${old_fstab_line}" | awk '{print $1}')
    targetmount=$(echo "${old_fstab_line}" | awk '{print $2}')

    # Get current Fstab UUID
    current_fstab_uuid=$(echo "${filesystem}" | sed -E "s|UUID=([0-9a-zA-Z-]+)|\1|")

    # Save FSTAB UUID
    if [[ -f "${devices_basepath}/${device_id}/${partition_number}/fstab.uuid" ]]
    then
        echo "${current_fstab_uuid}" > "${devices_basepath}/${device_id}/${partition_number}/fstab.uuid"
    fi

    # Echo
    echo -e "\tProcessing current Fstab Line: ${old_fstab_line}"

    # Define UUID Path
    device_uuid_path="/dev/disk/by-uuid/${current_fstab_uuid}"

    # Check if Device exists
    if [[ -L "${device_uuid_path}" ]]
    then
        # Get Device /dev/sdX by reading where the Link Points to
        device_real_path=$(readlink --canonicalize-missing "${device_uuid_path}")

        # Echo
        echo -e 

        # Initialize Value
        device_id=""

        # Find Link in Reverse to by-id Folder
        for item in /dev/disk/by-id/*
        do
            # Echo
            echo -e "\t\t- Compare ${item} against ${device_real_path}"

            # Get Real Path
            check_realpath=$(readlink --canonicalize-missing "/dev/disk/by-id/${item}")

            # Compare
            if [[ "${check_realpath}" == "${device_real_path}" ]]
            then
                if [[ "${device_id}" == "" ]]
                then
                    # Set Device id
                    device_id=$(basename "${check_realpath}")
                else
                    # Error: Duplicate Entry Found
                    echo "ERROR: Duplicate Entry found for ${device_id}"
                    exit 10
                fi
            fi
        done

        if [[ -z "${device_id}" ]]
        then
            # Error
            echo "ERROR: Device ID couldn't be found for ${device_uuid_path} / ${device_real_path}"
            exit 11
        fi

        # Echo
        echo -e "\t\tFound Matching Device ID in /dev/disk/by-id/${device_id} for ${device_uuid_path} (${device_real_path})"

        # Extract Device Name
        device_name=$(basename "${device_real_path}" | sed -E "s|^([a-zA-Z]+)([0-9]+)$|\1|")

        # Extract Partition Number
        partition_number=$(basename "${device_real_path}" | sed -E "s|^([a-zA-Z]+)([0-9]+)$|\2|")

        # Load new UUID
        if [[ -f "${devices_basepath}/${device_id}/${partition_number}/new.uuid" ]]
        then
            new_uuid=$(cat "${devices_basepath}/${device_id}/${partition_number}/new.uuid")
        else
            # Error
            echo "ERROR: new UUID not set for Device ${device_uuid_path} / ${device_real_path}"
            exit 12
        fi

        # Load new PARTUUID
        if [[ -f "${devices_basepath}/${device_id}/${partition_number}/new.partuuid" ]]
        then
            new_partuuid=$(cat "${devices_basepath}/${device_id}/${partition_number}/partnew.uuid")
        else
            # Error
            echo "ERROR: new PARTUUID not set for Device ${device_uuid_path} / ${device_real_path}"
            exit 13
        fi

        # Echo
        echo -e "\t[$((index_fstab_line+1))]"
        echo -e "\t\tProcessing Line: ${old_fstab_line}"
        echo -e "\t\t(Filesystem: ${filesystem} -> Target Mount Point: ${targetmount})"

        # Echo
        echo -e "\t\tDefine Change in UUID from ${current_fstab_uuid} to ${new_uuid} for Mount Point ${targetmount}"

        # New /etc/fstab Line
        new_fstab_line=$(echo "${old_fstab_line}" | sed -E "s|^UUID=([0-9a-zA-Z-]+)(\s.*)$|UUID=${new_uuid}\2|")

        # Store in new_fstab_lines
        # Not really needed anymore
        new_fstab_lines+=("${new_fstab_line}")

        # Echo
        echo -e "\t[$((index_fstab_line+1))]"
        echo -e "\t\tChanging ${destination}/etc/fstab Line"
        echo -e "\t\t\t- Old: ${old_fstab_line}"
        echo -e "\t\t\t- New: ${new_fstab_line}"

        # Check if old and new Fstab Lines are any different
        if [[ "${old_fstab_line}" != "${new_fstab_line}" ]]
        then
            # Perform Replacement
            sed -Ei "s|${old_fstab_line}|${new_fstab_line}|" "${destination}/etc/fstab"
        fi
    else
        # Error
        echo "ERROR: Device ${device_uuid_path} does NOT exist. Did you already run this Script and must reboot in order for the Kernel to be notified of the Changes ?"
        echo "ABORTING !"
        exit 7
    fi
done

# Copy tool to chroot folder
source "${toolpath}/modules/copy_tool_to_chroot.sh"

# Run inside-chroot/install_bootloader.sh inside chroot
chroot "${destination}" /bin/bash -c "/tools_install/${timestamp}/inside-chroot/install_bootloader.sh"

# Echo
echo "Unmounting Everything from Target Mountpoint"

# Unmount Chroot again
source "${toolpath}/umount_everything.sh"
