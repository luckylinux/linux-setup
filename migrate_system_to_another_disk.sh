#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Umount everything that was previosly mounted
source ${toolpath}/umount_everything.sh

# Ensure that the mointpoint exists and is empty
source ${toolpath}/modules/setup_mountpoint.sh

# Setup Requirements for the Installation (Packages will be installed on the currently running HOST)
installroot="" # Needed to ensure that we install on the Host
source ${toolpath}/modules/setup_requirements.sh

# Umount everything that was previosly mounted
source ${toolpath}/umount_everything.sh

# Init partitioning
source ${toolpath}/modules/init_partitioning.sh

# Setup disks
source ${toolpath}/modules/setup_partitions.sh

# Mount system
source ${toolpath}/modules/mount_system.sh

# Migrate system
source ${toolpath}/modules/migrate_system.sh

# Mount bind
source ${toolpath}/modules/mount_bind.sh

# Setup chroot
source ${toolpath}/modules/setup_chroot.sh
