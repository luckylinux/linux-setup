#/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# (Re)load configuration
source $toolpath/config.sh

# Mount system if not already mounted
source $toolpath/modules/mount_system.sh

# Install minimal system
debootstrap --exclude="${excludepackages}" --include="${includepackages}" "${release}" "${destination}" "${source}"

# Add swap to fstab
mkdir -p "${destination}/etc/"
echo "/dev/zvol/$rootpool/swap      none    swap    defaults        0       0" >> "${destination}/etc/fstab"

# Bind required filesystems
source $toolpath/modules/mount_bind.sh

# Copy APT sources
cp "${toolpath}/repositories/${distribution}/${release}/sources.list" "${destination}/etc/apt/sources.list"

# Copy GRUB configuration files
mkdir -p "${destination}/etc/default/grub.d"
cp "${toolpath}/files/etc/default/grub" "${destination}/etc/default/grub"
cp -ar "${toolpath}/files/etc/default/grub.d/*" "${destination}/etc/default/grub.d/"

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
