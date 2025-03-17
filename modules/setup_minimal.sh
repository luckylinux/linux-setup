#/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# (Re)load configuration
source $toolpath/load.sh

# Mount system if not already mounted
source $toolpath/modules/mount_system.sh

# Unmount Existing efi Devices (if mounted)
if [[ -d "${destination}/boot/efi" ]]
then
    for disk in "${disks[@]}"
    do
        if [[ -d "${destination}/boot/efi/${disk}" ]]
        then
            # Unmount Existing efi Devices (if mounted)
            if mountpoint -q "${destination}/boot/efi/${disk}"
            then
                umount "${destination}/boot/efi/${disk}"
            fi
        fi
    done
fi

# Unmount Existing boot Device (if mounted)
if mountpoint -q "${destination}/boot"
then
    umount "${destination}/boot"
fi

# Create /boot and /boot/efi/<disk> and prevent direct write to them, unless Partition has been mounted
mkdir -p "${destination}/boot"
chattr +i "${destination}/boot"
mount "${destination}/boot"

mkdir -p "${destination}/boot/efi"
chattr -i "${destination}/boot/efi"

for disk in "${disks[@]}"
do
     # Create required Subfolder
     mkdir -p "${destination}/boot/efi/${disk}"

     # Make sure that a Partition has been mounted there
     chattr +i "${destination}/boot/efi/${disk}"
done

# Mount boot Filesystems
if [ "${bootfs}" == "ext4" ]
then
        if [ "${numdisks_total}" -eq 1 ]
        then
                # Get UUID of Single Disk Partition
                UUID=$(blkid -s UUID -o value ${devices[0]}-part${boot_num})

                # Mount Filesystem
                mount ${devices[0]}-part${boot_num} ${destination}/boot
        else
                # Get UUID of MDADM Device
                UUID=$(blkid -s UUID -o value /dev/${mdadm_boot_device})

                # Mount Filesystem
                mount /dev/${mdadm_boot_device} ${destination}/boot
        fi

        # else
        #         echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
        #         exit 1
        # fi
fi

# Mount efi Filesystems
for disk in "${disks[@]}"
do
    # Get UUID of Single Disk Partition
    UUID=$(blkid -s UUID -o value "/dev/disk/by-id/${disk}-part${efi_num}")

    # Mount Filesystem
    mount "/dev/disk/by-id/${disk}-part${efi_num}" "${destination}/boot/efi/${disk}"
done

#if [ "xxxx" == "ext4" ]
#then
#        if [ "${numdisks_total}" -eq 2 ]
#        then
#                # Get UUID of MDADM Device
#                UUID=$(blkid -s UUID -o value /dev/${mdadm_efi_device})
#
#                # Mount Filesystem
#                mount /dev/${mdadm_efi_device} ${destination}/boot/efi
#        elif [ "${numdisks_total}" -eq 1 ]
#        then
#                # Get UUID of Single Disk Partition
#                UUID=$(blkid -s UUID -o value ${devices[0]}-part${efi_num})
#
#                # Mount Filesystem
#                mount ${devices[0]}-part${efi_num} ${destination}/boot/efi
#        else
#                echo "Only 1-Disk and 2-Disks Setups are currently supported. Aborting !"
#                exit 1
#        fi
#fi

# Install minimal system
debootstrap --exclude="${excludepackages}" --include="${includepackages}" "${release}" "${destination}" "${source}"

# Bind required filesystems
source $toolpath/modules/mount_bind.sh

# Copy APT sources
cp "${toolpath}/repositories/${distribution}/${release}/sources.list" "${destination}/etc/apt/sources.list"

# Copy GRUB configuration files
mkdir -p "${destination}/etc/default/grub.d"
cp "${toolpath}/files/etc/default/grub" "${destination}/etc/default/grub"
cp -ar ${toolpath}/files/etc/default/grub.d/* "${destination}/etc/default/grub.d/"

if [[ -f "${destination}/etc/default/grub.d/zfs.cfg" ]]
then
    sed -Ei "s|${rootpool}/ROOT/debian|${rootpool}/ROOT/${distribution}|g" "${destination}/etc/default/grub.d/zfs.cfg"
fi

# Configure hostname
echo "${targethostname}" > "${destination}/etc/hostname"

# Configure host file
echo "127.0.0.1		localhost" > "${destination}/etc/hosts"
echo "${ipaddress}	${targethostname}.${targetdomainname} ${targethostname} localhost" >> "${destination}/etc/hosts"

echo "# The following lines are desirable for IPv6 capable hosts" >> "${destination}/etc/hosts"
echo "::1     		localhost ip6-localhost ip6-loopback" >> "${destination}/etc/hosts"
echo "ff02::1 		ip6-allnodes" >> "${destination}/etc/hosts"
echo "ff02::2 		ip6-allrouters" >> "${destination}/etc/hosts"

# Configure network interface
ifconfig
echo "Possible network interface names are: " && ls /sys/class/net/
read -p "Enter network interface name: " interfacename

mkdir -p "${destination}/etc/network/interfaces.d"

# Create Persistent Interface Name using UDEV
macaddress=$(find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo -printf "%P: " -execdir cat {}/address \; | grep ${interfacename} | sed -E "s|${interfacename}:\s*?([0-9a-fA-F:]+)$|\1|")

echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${macaddress}\", ATTR{type}==\"1\", KERNEL==\"*\", NAME=\"${interfacename}\"" >> "${destination}/etc/udev/rules.d/30-net_persistent_names.rules"

if [[ "${ipconfiguration}" == "static" ]]
then
   echo "auto ${interfacename}" > "${destination}/etc/network/interfaces.d/${interfacename}"
   #echo "allow-hotplug ${interfacename}" >> "${destination}/etc/network/interfaces.d/${interfacename}" # Should prevent hanging during boot process
   echo "iface ${interfacename} inet static" >> "${destination}/etc/network/interfaces.d/${interfacename}"
   echo "	address ${ipaddress}" >> "${destination}/etc/network/interfaces.d/${interfacename}"
   echo "	netmask ${subnetmask}" >> "${destination}/etc/network/interfaces.d/${interfacename}"
   echo "	gateway ${defgateway}" >> "${destination}/etc/network/interfaces.d/${interfacename}"
elif [[ "${ipconfiguration}" == "dhcp" ]]
then
   echo "auto ${interfacename}" > "${destination}/etc/network/interfaces.d/${interfacename}"
   #echo "allow-hotplug ${interfacename}" >> "${destination}/etc/network/interfaces.d/${interfacename}" # Should prevent hanging during boot process
   echo "iface ${interfacename} inet dhcp" >> "${destination}/etc/network/interfaces.d/${interfacename}"
else
   echo "ERROR: Network Configuration Type <${ipconfiguration}> is NOT supported. Must be one of: <static> or <dhcp>"
   echo "ABORTING ..."
   exit 9
fi

echo "Network configured for <${interfacename}> in <${ipconfiguration}> mode"

# Setup tools over NFS
if [[ "$setupnfstools" == "yes" ]]
then
   echo "# Tools over NFS" >> "${destination}/etc/fstab"
   echo "192.168.1.223:/export/tools          /tools_nfs           nfs             rw,user=tools,auto,nfsvers=3          0       0"  >> "${destination}/etc/fstab"
   mkdir -p  "${destination}/tools_nfs"
   chattr +i "${destination}/tools_nfs"
fi

# Setup & perform chroot
source $toolpath/modules/setup_chroot.sh
