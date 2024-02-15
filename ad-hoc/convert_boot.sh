#!/bin/bash

# Mount Current /boot partition
mount /boot

# Generate Timestamp for backup archive
timestamp=$(date +"%Y%m%d")

# Backup Current /boot partition content
tar cvzf /boot_$timestamp.tar.gz /boot

# Convert System's /boot partition
for device in "${devices[@]}"
    # Modify Partition Type

    # 
    
done

# Multi-Disk Build new RAID device 
# Single Disk: format as a normal partition for single drive
