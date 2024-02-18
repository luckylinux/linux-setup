#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Create folder if not exist
mkdir -p $destination

# Prevent files to being created without any FS mounted
chattr +i $destination

# Unlock encrypted root (if applicable)
source $toolpath/modules/unlock_encrypted_root.sh

# Mount system
source $toolpath/modules/mount_system.sh

# Mount bind
source $toolpath/modules/mount_bind.sh

# Setup chroot
source $toolpath/modules/setup_chroot.sh
