#/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# (Re)load configuration
source $toolpath/config.sh

# Mount system if not already mounted
source $toolpath/modules/mount_system.sh

# Install minimal system
debootstrap --exclude=$excludepackages "${release}" "${destination}" "${source}"

# Add swap to fstab
mkdir -p "${destination}/etc/"
echo "/dev/zvol/$rootpool/swap      none    swap    defaults        0       0" >> "${destination}/etc/fstab"

# Bind required filesystems
source $toolpath/modules/mount_bind.sh

# Copy APT sources
cp "./files/sources_${release}.list" "${destination}/etc/apt/sources.list"
cp "./files/02proxy" "${destination}/etc/apt/apt.conf.d/02proxy"

# Copy GRUB configuration file
cp ./files/grub "${destination}/etc/default/grub"

# Configure hostname
echo "$name" > "${destination}/etc/hostname"

# Configure host file
echo "127.0.0.1		localhost" > "${destination}/etc/hosts"
echo "${ipaddress}	${name}.${domainname} ${name} localhost" >> "${destination}/etc/hosts"

echo "# The following lines are desirable for IPv6 capable hosts" >> "${destination}/etc/hosts"
echo "::1     		localhost ip6-localhost ip6-loopback" >> "${destination}/etc/hosts"
echo "ff02::1 		ip6-allnodes" >> "${destination}/etc/hosts"
echo "ff02::2 		ip6-allrouters" >> "${destination}/etc/hosts"

# Configure network interface
ifconfig
echo "Possible network interface names are: " && ls /sys/class/net/
read -p "Enter network interface name: " interfacename

mkdir -p "${destination}/etc/network/interfaces.d"
echo "auto ${interfacename}" > "${destination}/etc/network/interfaces.d/${interfacename}"
#echo "iface ${interfacename} inet dhcp" >> "${destination}/etc/network/interfaces.d/${interfacename}"
echo "iface ${interfacename} inet static" >> "${destination}/etc/network/interfaces.d/${interfacename}"
echo "	address ${ipaddress}" >> "${destination}/etc/network/interfaces.d/${interfacename}"
echo "	netmask ${subnetmask}" >> "${destination}/etc/network/interfaces.d/${interfacename}"
echo "	gateway ${defgateway}" >> "${destination}/etc/network/interfaces.d/${interfacename}"
echo "Network configured for <${interfacename}>"

# Copy configuration script to chroot environment
mkdir -p "${destination}/tools_install"
cp -ra $toolpath/* "${destination}/tools_install"
#cp ./config.sh "${destination}/tools_install/config.sh"
#cp ./files/inside_chroot.sh "${destination}/tools_install/setup_chroot.sh"
#cp ./files/finish_installation.sh "${destination}/tools_install/setup_system_after_reboot.sh"
sleep 2

# Setup tools
echo "# Tools over NFS" >> "${destination}/etc/fstab"
echo "192.168.1.223:/export/tools          /tools_nfs           nfs             rw,user=tools,auto,nfsvers=3          0       0"  >> "${destination}/etc/fstab"
mkdir -p  "${destination}/tools_nfs"
chattr +i "${destination}/tools_nfs"

# Chroot into the new environment
chroot "${destination}" /bin/bash --login
