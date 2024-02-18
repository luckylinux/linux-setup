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
        echo "${disk1}_crypt" UUID=$(blkid -s UUID -o value ${device1}-part${root_num}) none \
        luks,discard,initramfs > "${destination}/etc/crypttab"

        if [ $numdisks -eq 2 ]
        then
                echo "${disk2}_crypt" UUID=$(blkid -s UUID -o value ${device2}-part${root_num}) none \
                 luks,discard,initramfs >> "${destination}/etc/crypttab"
        fi
fi

if [ "$rootfs" == "zfs" ]
then
    echo "Skipping Configuration of FSTAB due to ZFS automount generator"
elif [ "$rootfs" == "ext4" ]
then
        if [ "$numdisks" -eq 2 ]
        then
                # Configure MDADM Array in /etc/fstab
                UUID=$(blkid -s UUID -o value /dev/${mdadm_root_device})
                echo "# / on ext4 with MDADM Software Raid-1" >> /etc/fstab
                echo "UUID=$UUID        /   ext4            auto            0      1" >> /etc/fstab

                # Also add MDADM Array to /etc/mdadm/mdadm.conf
                # When this is enabled, mdadm does NOT create the devices as expected
                # The boot process might also be interrupted, dropping you to an emergency shell
                #mdadm --detail --scan | grep "/dev/${mdadm_root_device}" >> /etc/mdadm/mdadm.conf

                # Alternative is to use a custom Systemd service together with a custom made automount mdadm-assemble.service
                # The installation is handle by modules/setup_systemd_mdadm_assemble.sh
                tee /etc/mdadm/root.mdadm << EOF
#!/bin/bash

# Load Global Configuration
#source /etc/mdadm/global.sh

# Define mdadm Device
mdadm_device="/dev/${mdadm_root_device}"

# List Member Devices
member_devices=()
member_devices+=( "${devices[0]}-part${root_num}" )
member_devices+=( "${devices[1]}-part${root_num}" )
EOF

                # Install tool
                source $toolpath/modules/setup_systemd_mdadm_assemble.sh

        elif [ "$numdisks" -eq 1 ]
        then
                # Configure Partition in /etc/fstab
                UUID=$(blkid -s UUID -o value $device1-part${root_num})
                echo "# / on ext4" >> /etc/fstab
                echo "UUID=$UUID        /   ext4            auto            0      1" >> /etc/fstab
        else
                echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
                exit 1
        fi
else
        echo "Only ZFS and EXT4 are currently supported. Aborting !"
        exit 1
fi
