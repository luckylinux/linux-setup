#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Close LUKS devices if applicable
# If root device is encrypted
if [ "${encryptrootfs}" == "luks" ]
then
    for disk in "${disks[@]}"
    do
        # Close Device
        if [[ -e "/dev/mapper/${disk}_root_crypt" ]]
        then
            cryptsetup luksClose "${disk}_root_crypt"
        fi
    done
fi
