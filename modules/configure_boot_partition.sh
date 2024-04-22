#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source $toolpath/config.sh

# Configure FSTAB
if [ "$bootfs" == "zfs" ]
then
    echo "Skipping Configuration of FSTAB due to ZFS automount generator"
elif [ "$bootfs" == "ext4" ]
then
        if [ "$numdisks" -eq 2 ]
        then
                # Install mdadm if not already installed
                if [[ -z $(command -v mdadm) ]]
                then
                    apt-get install -y mdadm
                fi

                # Configure MDADM Array in /etc/fstab
                UUID=$(blkid -s UUID -o value /dev/${mdadm_boot_device})
                echo "# /boot on ext4 with MDADM Software Raid-1" >> /etc/fstab
                echo "UUID=$UUID	/boot	ext4            auto,nofail,x-systemd.automount            0      1" >> /etc/fstab

		# Also add MDADM Array to /etc/mdadm/mdadm.conf
                # When this is enabled, mdadm does NOT create the devices as expected
                # The boot process might also be interrupted, dropping you to an emergency shell
		#mdadm --detail --scan | grep "/dev/${mdadm_boot_device}" >> /etc/mdadm/mdadm.conf

		# Alternative is to use a custom Systemd service together with a custom made automount mdadm-assemble.service
		# The installation is handle by modules/setup_systemd_mdadm_assemble.sh
		tee /etc/mdadm/boot.mdadm << EOF
#!/bin/bash

# Load Global Configuration
#source /etc/mdadm/global.sh

# Define mdadm Device
mdadm_device="/dev/${mdadm_boot_device}"

# List Member Devices
member_devices=()
member_devices+=( "${devices[0]}-part${boot_num}" )
member_devices+=( "${devices[1]}-part${boot_num}" )
EOF

	        # Install tool
                source $toolpath/modules/setup_systemd_mdadm_assemble.sh

        elif [ "$numdisks" -eq 1 ]
        then
                # Configure Partition in /etc/fstab
                UUID=$(blkid -s UUID -o value $device1-part${boot_num})
		echo "# /boot on ext4" >> /etc/fstab
                echo "UUID=$UUID        /boot   ext4            auto,nofail,x-systemd.automount            0      1" >> /etc/fstab
        else
                echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
                exit 1
        fi
else
        echo "Only ZFS and EXT4 are currently supported. Aborting !"
        exit 1
fi

# Reload Systemd as applicable due to changed /etc/fstab
systemctl daemon-reload
