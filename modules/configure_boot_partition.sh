#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source "${toolpath}/load.sh"

# Configure FSTAB
if [ "$bootfs" == "zfs" ]
then
    echo "Skipping Configuration of FSTAB due to ZFS automount generator"
elif [ "$bootfs" == "ext4" ]
then
        if [ "${numdisks_total}" -eq 1 ]
        then
                # Configure Partition in /etc/fstab
                UUID=$(blkid -s UUID -o value ${devices[0]}-part${boot_num})
		echo "# /boot on ext4" >> /etc/fstab
                echo "UUID=$UUID	/boot			ext4		auto,noatime,nofail,x-systemd.automount					0	1" >> /etc/fstab
        else
                # Install mdadm if not already installed
                if [[ -z $(command -v mdadm) ]]
                then
                    install_packages_unattended mdadm
                fi

                # Configure MDADM Array in /etc/fstab
                UUID=$(blkid -s UUID -o value /dev/${mdadm_boot_device})
                echo "# /boot on ext4 with MDADM Software Raid-1" >> /etc/fstab
                echo "UUID=$UUID	/boot			ext4		auto,noatime,nofail,x-systemd.automount					0	1" >> /etc/fstab

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
EOF

                # Add each Disk to the MDADM Configuration
                for disk in "${disks[@]}"
                do
                    echo "member_devices+=( \"/dev/disk/by-id/${disk}-part${boot_num}\" )" >> /etc/mdadm/boot.mdadm
                done

	        # Install Tool / Wrapper for Managing MDADM Devices
                source ${toolpath}/modules/setup_systemd_mdadm_assemble.sh

        fi
        # else
        #         echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
        #         exit 1
        # fi
else
        echo "Only ZFS and EXT4 are currently supported. Aborting !"
        exit 1
fi

# Reload Systemd as applicable due to changed /etc/fstab
systemctl daemon-reload
