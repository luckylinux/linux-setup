#!/bin/bash

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ] 
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

# Determine toolpath
scriptpath=$(dirname "${BASH_SOURCE[0]}")
parentpath=$(dirname "$scriptpath")
toolpath="$( cd "$( dirname "$scriptpath" )" > /dev/null && pwd )"

echo "Starting script"

# Load Configuration
source $toolpath/config.sh

# Load default Shell Profile
source /etc/profile

# Change Directory
cd /tools_install/$timestamp

# Return
return
