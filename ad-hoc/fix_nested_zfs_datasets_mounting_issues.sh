#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Load Functions
source ${toolpath}/functions.sh

# Unmount everything by default
zfs umount -a

# Wait a bit
sleep 2

# Mount just the root dataset
zfs mount ${rootpool}/ROOT/$distribution

# Get list of datasets
datasets=$(zfs list -H -o name | grep -i "${rootpool}" | xargs -n1)

# Generate timestamp
timestamp=$(date +"%Y%m%d")

# Create Snapshot
zfs snapshot -r ${rootpool}@${timestamp}_fix_nested_zfs_datasets

# Loop over Datasets
while IFS= read -r dataset
do
    # Get mountpoint
    mountpt=$(zfs get -H mountpoint -o value ${dataset})

    # If it's NOT the root dataset and it's a dataset that IS supposed to be mounted
    if [ "${mountpt}" != "none" ] && [ "${mountpt}" != "${destination}" ] && [ "${mountpt}" != "-" ]
    then
        # If it's really a dataset, NOT a zvol
        if [ ! -b /dev/zvol/${dataset} ]
        then
            # Echo
            echo -e "Processing Dataset ${dataset} at ${mountpt}"

            # Get attributes
            attrs=$(lsattr -Ra ${mountpt} | head -1 | sed -E "s|^([a-z-]+?)\s.*|\1|g")
            #attrs=$(lsattr -Ra ${mountpt} | head -1 | head -c 22)
            echo -e "\t Attributes: ${attrs}"

            # Check if Mountpoint is empty or not
            if [ -z "$(ls -A ${mountpt})" ]
            then
                # Echo
                echo -e "\t Folder ${mountpt} is empty"
            else
                # Echo
                echo -e "\t Folder ${mountpt} is NOT empty"

                # Rename Folder to _local_${timestamp}
                mv ${mountpt} ${mountpt}_local_${timestamp}

                # Create empty Folder
                mkdir -p ${mountpt}
            fi

            # Echo
            echo -e "\t Set IMMUTABLE Flag on ${mountpt}"

            # Set Immutable Flag
            chattr +i ${mountpt}

            # Echo
            echo -e "\t Mount ${dataset} to ${mountpt}"

            # Mount Filesystem
            zfs mount ${dataset}

            # Move files back and merge, if needed
            if [[ -d "${mountpt}_local_${timestamp}" ]]
            then
                # Move Files (ONLY if they are newer)
                rsync -aPAXUHEt --remove-source-files --update ${mountpt}_local_${timestamp}/ ${mountpt}
                #mv ${mountpt}_local_${timestamp}/* ${mountpt}/

		# Remove empty Folders
		find ${mountpt}_local_${timestamp} -type d -empty -delete

                # Remove Folder
                rmdir ${mountpt}_local_${timestamp}
            fi
        fi
    fi

done <<< "${dataset}s"
