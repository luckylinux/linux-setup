#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Setup CLEVIS for automated disk unlocking
add_rfc3442_hook() {
  cat << EOF > /etc/initramfs-tools/hooks/add-rfc3442-dhclient-hook
#!/bin/sh

PREREQ=""

prereqs()
{
        echo "\$PREREQ"
}

case \$1 in
prereqs)
        prereqs
        exit 0
        ;;
esac

if [ ! -x /sbin/dhclient ]; then
        exit 0
fi

. /usr/share/initramfs-tools/scripts/functions
. /usr/share/initramfs-tools/hook-functions

# Source: https://github.com/latchset/clevis/issues/148#issuecomment-882103016
#    and: https://github.com/latchset/clevis/issues/148#issuecomment-882103016
local_libdir="/lib/x86_64-linux-gnu"
local_found="" lib="" f=""
for lib in libnss_files libnss_dns libresolv; do
    local_found=""
    for f in "\${local_libdir}/\${lib}.so".?; do
        [ -e "\${f}" ] || continue
        [ "\${verbose}" = "y" ] && echo "dns: \${lib}: \${f}"
        copy_file library "\${f}"
        local_found="\${f}"
    done
    [ -n "\${local_found}" ] || echo "WARNING: no \${local_libdir}/\${lib}.? file" 1>&2
done

mkdir -p \$DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
cp -a /etc/dhcp/dhclient-exit-hooks.d/rfc3442-classless-routes \$DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
EOF

  chmod +x /etc/initramfs-tools/hooks/add-rfc3442-dhclient-hook
}


# Install hook
add_rfc3442_hook

# Update APT Lists
update_lists

# Install clevis on the system and add clevis to the initramfs
install_packages_unattended clevis clevis-luks clevis-initramfs cryptsetup-initramfs jq

# Ask for password
read -s -p "Enter encryption password: " password

# (OLD LOOP) For each keyserver
# counter=1
# for keyserver in "${keyservers[@]}"
# do
#     # Get TANG Server Key
#     curl -sfg http://$keyserver/adv -o /tmp/keyserver-$counter.jws
# 
#      # Check which keys are currently used via CLEVIS
#      for disk in "${disks[@]}"
#      do
#          list_device=$(clevis luks list -d /dev/disk/by-id/${disk}-part${root_num})
# 
#          # Bind device to the TANG server via CLEVIS
#          if [[ "${list_device}" == *"${keyserver}"* ]]
#          then
#              echo "Keyserver <$keyserver> is already installed"
#          else
#              echo "Install Keyserver <$keyserver> onto /dev/disk/by-id/${disk}-part${root_num} LUKS Header"
#              # echo $password | clevis luks bind -d /dev/disk/by-id/${disk}-part${root_num} tang "{\"url\": \"http://$keyserver\" , \"adv\": \"/tmp/keyserver-$counter.jws\" }"
#              echo $password | clevis luks bind -d /dev/disk/by-id/${disk}-part${root_num} sss ${tangkeyserverdict}
#          fi
#      done
#
#      # Increment counter
#      counter=$((counter+1))
# done



# Use pre-build Dictionary
for disk in "${disks[@]}"
do
    echo "Install Keyservers onto /dev/disk/by-id/${disk}-part${root_num} LUKS Header"
    echo ${tangkeyserverdict} | jq -r --color-output
    echo $password | clevis luks bind -d /dev/disk/by-id/${disk}-part${root_num} -s ${clevis_luks_keyslot} -f sss "${tangkeyserverdict}"
done

# Clear password from memory
unset $password

# Update initramfs
regenerate_initrd

# Get information
for disk in "${disks[@]}"
do
    cryptsetup luksDump /dev/disk/by-id/${disk}-part${root_num}
    clevis luks list -d /dev/disk/by-id/${disk}-part${root_num}
done