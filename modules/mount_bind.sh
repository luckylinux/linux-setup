#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Mounts required
if mountpoint -q "${destination}/dev"
then
        #echo "${destination}/dev is already mounted" 	# Echo
	x=1	 				     	# Silent
else
        mkdir -p "${destination}/dev"
        mount --rbind /dev  "${destination}/dev"
fi

if mountpoint -q "${destination}/proc"
then
        #echo "${destination}/proc is already mounted"	# Echo
	x=1						# Silent
else
        mkdir -p "${destination}/proc"
        mount --rbind /proc "${destination}/proc"
fi

if mountpoint -q "${destination}/sys"
then
        #echo "${destination}/sys is already mounted"	# Echo
	x=1						# Silent
else
        mkdir -p "${destination}/sys"
        mount --rbind /sys "${destination}/sys"
fi
