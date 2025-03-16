#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Settings
compression_level="9"
create_image="yes"
create_archive="yes"

# Save current path
currentpath=$(pwd)

# Attempt to get Device from Command Line Argument
device=${1-""}

# Attempt to get Save Path from Command Line Argument
destinationpath=${2-""}

# Install requirements
apt-get -y install fdisk parted gddrescue coreutils

# Ask for Device to backup interactively
while [ ! -b "${device}" ] || [ -z "${device}" ]
do
    read -p "Enter device to backup (e.g. /dev/sdc): " device
    disk="${device/\/dev\//""}"
done

# Ask for Destination Path for backup interactively
while [ ! -d "${destinationpath}" ] || [ -z "${destinationpath}" ]
do
    read -p "Enter Backup Destination (e.g. /home/user/target) - Must exist already: " destinationpath
done

# Generate timestamp
timestamp=$(date +%Y%m%d)

# Define Target Path
targetpath="${destinationpath}/${timestamp}"

# Create Folder if not exist yet
mkdir -p "${targetpath}"

# Labetling of NVME Partitions is slightly different, so need to adjust for that
if [[ "${device}" == "/dev/nvme"* ]]
then
    partition_prefix="p"
# elif [[ "${device}" == "/dev/sd"* ]]
# then
else
   partition_prefix=""
fi

# For each partition

# mapfile -t listPartitions < <( find / -iname $device[0-9]* )
# mapfile -t listPartitions < <( find /dev -iwholename "${device}[0-9]"* | sed -E "s|$\{device\}||g" )
mapfile -t listPartitions < <( find /dev -iwholename "${device}${partition_prefix}[0-9]"* | sed -E "s|${device}${partition_prefix}||g" )
# partitions=$(find / -iname $device[0-9]*)
# echo "Found $partitions"
# totalPartitions=$(grep -c "$disk[0-9]" /proc/partitions)
# bootnumber=$(( $totalPartitions - 1 ))
# rootnumber=$totalPartitions

# Make sure to unmount devices before starting
# for (( p=1; p<$totalPartitions; p++ ))
for p in "${listPartitions[@]}"
do
    echo "Check if ${device}${p} is a valid Block Device"
    if [[ -b "${device}${p}" ]]
    then
        umount "${device}${partition_prefix}${p}"
    fi
done

# Backup partition table
sfdisk -d $device > ${targetpath}/partition_table_$timestamp.txt

# Backup MBR
dd if="${device}" of="${targetpath}/mbr-${timestamp}.img" bs=512 count=1

if [[ "${create_image}" == "yes" ]]
then
   # Backup full Device
   # dd if="${device}" conv=noerror,sync iflag=fullblock status=progress | gzip -$compression -c > "${targetpath}/device-${timestamp}.img.gz"

   # if totalPartitions > 2
   # for (( p=1; p<$totalPartitions; p++ ))
   for p in "${listPartitions[@]}"
   do
       echo "Check if ${device}${p} is a valid Block Device"
       if [[ -b "${device}${p}" ]]
       then
           echo "Back up Partition ${device}${p} as a .img.gz Compressed Image"
           dd if="${device}${partition_prefix}${p}" conv=noerror,sync iflag=fullblock status=progress | gzip -$compression -c > "${targetpath}/partition-${p}.img.gz"
       fi
   done
fi

if [[ "${create_archive}" == "yes" ]]
then
   # Create Root Mountpoint
   mkdir -p /mnt/backup

   # for (( p=1; p<$totalPartitions; p++ ))
   for p in "${listPartitions[@]}"
   do
       echo "Check if ${device}${p} is a valid Block Device"
       if [[ -b "${device}${p}" ]]
       then
           echo "Back up Partition ${device}${p} as a .tar.gz Archive"
           umount "/mnt/backup/part${p}"
           mkdir -p "/mnt/backup/part${p}"
           chattr +i "/mnt/backup/part${p}"
           mount "${device}${partition_prefix}${p}" "/mnt/backup/part${p}"
           cd "/mnt/backup/part${p}"
           mkdir -p "${targetpath}/part${p}"
           tar cvfz "${targetpath}/part${p}/part${p}-${timestamp}.tar.gz" "./"
           cd /mnt/backup
           umount "${device}${partition_prefix}${p}"
        fi
    done
fi

# Change back to current path
cd $currentpath
