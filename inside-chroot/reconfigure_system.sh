#!/bin/bash

# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source "${toolpath}/load.sh"

# Configure /boot Partition & /etc/fstab
source ${toolpath}/modules/configure_boot_partition.sh

# Configure EFI Partition & /etc/fstab
source ${toolpath}/modules/configure_efi_partition.sh

# Configure root Partition & /etc/fstab
source ${toolpath}/modules/configure_root_partition.sh

# Configure data Partition & /etc/fstab
if [[ "${separate_data}" == "yes" ]]
then
    source ${toolpath}/modules/configure_data_partition.sh
fi

# Setup Clevis
if [ "$clevisautounlock" == "yes" ]
then
    source ${toolpath}/modules/setup_clevis_nbde.sh
fi

# Setup Dropbear
if [ "$dropbearunlock" == "yes" ]
then
    source ${toolpath}/modules/setup_dropbear_unlock.sh
fi

# (Re)install Bootloader
source ${toolpath}/inside-chroot/install_bootloader.sh
