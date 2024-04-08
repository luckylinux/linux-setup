#!/bin/bash

# Do NOT Abort on errors
#set -e

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Mount Current /boot partition
mount /boot

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d")

# Execute EFI Device(s) Setup
source $toolpath/modules/setup_efi_partition.sh

# Create /boot/efi folder and prevent direct writing (i.e. a partition must first be mounted inside to enable writing)
mkdir -p /boot/efi
chattr +i /boot/efi

# Configure FSTAB
source $toolpath/modules/configure_efi_partition.sh

# Mount the newly created boot device
mount /boot/efi
