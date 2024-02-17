#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Mounts required
if mountpoint -q "${destination}/dev"
then
        echo "${destination}/dev is already mounted"
else
        mkdir -p "${destination}/dev"
        mount --rbind /dev  "${destination}/dev"
fi

if mountpoint -q "${destination}/proc"
then
        echo "${destination}/proc is already mounted"
else
        mkdir -p "${destination}/proc"
        mount --rbind /proc "${destination}/proc"
fi

if mountpoint -q "${destination}/sys"
then
        echo "${destination}/sys is already mounted"
else
        mkdir -p "${destination}/sys"
        mount --rbind /sys "${destination}/sys"
fi

# Chroot into the environment
chroot "${destination}" /bin/bash --login
