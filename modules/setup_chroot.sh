#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Bind required filesystems
source $toolpath/modules/mount_bind.sh

# Chroot into the environment
chroot "${destination}" /bin/bash --login
