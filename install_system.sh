#!/bin/bash

# Define toolpath
toolpath=$(pwd)

# Load configuration
source config.sh

# Umount previosuly mounted pools & filesystems
umount $destination/{dev,sys,proc}
zfs umount -a
zfs umount $rootpool
zfs umount $rootpool/ROOT/$distribution
zpool export -f $rootpool
echo "\nWARNING: In case of errors it might be easier to just REBOOT the system\n"
sleep 5

# Init partitioning
source modules/init_partitioning.sh

# Setup disks
source modules/setup_partitions.sh

# Setup datasets
source modules/setup_datasets.sh

# Setup minimal system
source modules/setup_minimal.sh
