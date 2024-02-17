#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Create folder if not exist yet
mkdir -p "${destination}/tools_install"
mkdir -p "${destination}/tools_install/$timestamp"

# Copy configuration script to chroot environment
cp -ra $toolpath/* "${destination}/tools_install"

# Wait
sleep 1
