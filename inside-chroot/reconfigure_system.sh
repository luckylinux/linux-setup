#!/bin/bash

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ] 
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load Configuration
source $toolpath/config.sh

# Configure /boot Partition & /etc/fstab
source $toolpath/modules/configure_boot_partition.sh

# Configure EFI Partition & /etc/fstab
source $toolpath/modules/configure_efi_partition.sh

# Configure / Partition & /etc/fstab
source $toolpath/modules/configure_root_partition.sh

# Setup Clevis
if [ "$clevisautounlock" == "yes" ]
then
    source $toolpath/modules/setup_clevis_nbde.sh
fi
