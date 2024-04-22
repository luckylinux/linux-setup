#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Ask for Password if Applicable
if [[ "${clevisautounlock}" == "no" ]]
then
    read -s -p "Enter Password for unlocking Cryptsetup LUKS Encrypted Devices: " password
fi

# If it's LUKS encrypted
if [ "$encryptrootfs" == "luks" ]
then
	counter=0
	for disk in "${disks[@]}"
	do
		if [[ "${clevisautounlock}" == "yes" ]]
		then
			# Clevis Unlock
		        clevis luks unlock -d "/dev/disk/by-id/${disk}-part${root_num}" -n "${disk}_crypt"
		else
      			# Password Unlock
		        echo -n $password | cryptsetup open "/dev/disk/by-id/${disk}-part${root_num}" "${disk}_crypt"
		fi

		# Increment counter
	        counter=$((counter+1))
	done
fi

# Unset password
unset password
unset $password
