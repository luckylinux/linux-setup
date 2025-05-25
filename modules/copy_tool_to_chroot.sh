#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Create folder if not exist yet
mkdir -p "${destination}/tools_install"
mkdir -p "${destination}/tools_install/$timestamp"

# Copy configuration script to chroot environment
cp -ra $toolpath/* "${destination}/tools_install/$timestamp"

# Wait
sleep 1
