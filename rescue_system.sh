#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Create folder if not exist
mkdir -p $destination

# Prevent files to being created without any FS mounted
chattr +i $destination

# Mount system
source $toolpath/modules/mount_system.sh

# Mount bind
source $toolpath/modules/mount_bind.sh

# Setup chroot
source $toolpath/modules/setup_chroot.sh
