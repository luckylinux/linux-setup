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

# Init partitioning
source ${toolpath}/modules/init_partitioning.sh

# Setup disks
source ${toolpath}/modules/setup_partitions.sh


if [[ "${rootfs}" == "zfs" ]]
then
    # Setup root datasets
    source ${toolpath}/modules/setup_root_datasets.sh
fi

if [ "${distribution}" == "ubuntu" ] && [ "${rootpool_separate_datasets}" == "yes" ]
then
    # Setup additional datasets for Ubuntu
    source ${toolpath}/modules/setup_ubuntu_separate_datasets.sh
fi

# Setup minimal system
source ${toolpath}/modules/setup_minimal.sh
