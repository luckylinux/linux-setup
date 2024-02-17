#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load config
source $toolpath/config.sh

# If root device is encrypted
if [ "$encryptrootfs" == "luks" ]
then
        # Enable Disk in Crypttab for initramfs
        echo "${disk1}_crypt" UUID=$(blkid -s UUID -o value ${device1}-part{$root_num}) none \
        luks,discard,initramfs > "${destination}/etc/crypttab"

        if [ $numdisks -eq 2 ]
        then
                echo "${disk2}_crypt" UUID=$(blkid -s UUID -o value ${device2}-part${root_num}) none \
                 luks,discard,initramfs >> "${destination}/etc/crypttab"
        fi
fi
