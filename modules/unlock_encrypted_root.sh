#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

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
