#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Number of Times to repeat to ensure that everything is properly unmounted
# 2 is usually a good Value
NUM_UMOUNT_REPEAT=2

for i in $(seq 1 1 ${NUM_UMOUNT_REPEAT})
do
    # Umount previosuly mounted bind mounts
    source ${toolpath}/modules/umount_bind.sh

    # Force Chroot Processes to stop
    source ${toolpath}/modules/stop_chroot_processes.sh

    # Umount previosuly mounted Chroot
    source ${toolpath}/modules/umount_chroot.sh

    # Umount previosuly mounted ZFS Pools
    source ${toolpath}/modules/umount_zfs.sh

    # Umount previosuly assembled MDADM Arrays
    source ${toolpath}/modules/umount_mdadm.sh

    # Umount everything that remains by force
    source ${toolpath}/modules/umount_force_all.sh

    # Echo for difficult cases
    echo -e "\nWARNING: In case of errors it might be easier to just REBOOT the system\n"
    sleep 5
done
