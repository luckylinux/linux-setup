#!/bin/bash

# Used if we can run directly a script when entering chroot
# So that the user doesn't need to manually source /etc/profile within the chroon and
# cd to /tools_install/$timestamp

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

echo "Starting script"

# Load Configuration
source $toolpath/load.sh

# Load default Shell Profile
source /etc/profile

# Change Directory
cd /tools_install/$timestamp

# Return
return
