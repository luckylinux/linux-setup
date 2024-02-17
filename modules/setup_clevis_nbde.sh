#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

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

local_libdir="/lib/x86_64-linux-gnu"
local_found="" lib="" f=""
for lib in libnss_files libnss_dns libresolv; do
    local_found=""
    for f in "$local_libdir/$lib.so".?; do
        [ -e "$f" ] || continue
        [ "$verbose" = "y" ] && echo "dns: $lib: $f"
        copy_file library "$f"
        local_found="$f"
    done
    [ -n "$local_found" ] || echo "WARNING: no $local_libdir/$lib.? file" 1>&2
done

. /usr/share/initramfs-tools/scripts/functions
. /usr/share/initramfs-tools/hook-functions

mkdir -p \$DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
cp -a /etc/dhcp/dhclient-exit-hooks.d/rfc3442-classless-routes \$DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
EOF

  chmod +x /etc/initramfs-tools/hooks/add-rfc3442-dhclient-hook
}


# Install hook
add_rfc3442_hook

# Update APT Lists
apt-get update

# Install clevis on the system and add clevis to the initramfs
apt-get install --yes clevis clevis-luks clevis-initramfs cryptsetup-initramfs

# Ask for password
read -s -p "Enter encryption password: " password

# For each keyserver
counter=1
for keyserver in "${keyservers[@]}"
do
     # Get TANG Server Key
     curl -sfg http://$keyserver/adv -o /tmp/keyserver-$counter.jws

     # Check which keys are currently used via CLEVIS
     list_device1=$(clevis luks list -d $device1-part4)
     list_device2=$(clevis luks list -d $device2-part4)

     # Bind device to the TANG server via CLEVIS
     # Device 1
     if [[ "${list_device1}" == *"${keyserver}"* ]]; then
         echo "Keyserver <$keyserver> is already installed"
     else
         echo "Install Keyserver <$keyserver> onto $device1 LUKS Header"
         echo $password | clevis luks bind -d $device1-part4 tang "{\"url\": \"http://$keyserver\" , \"adv\": \"/tmp/keyserver-$counter.jws\" }"
     fi

     # Device 2
     if [[ "${list_device2}" == *"${keyserver}"* ]]; then
         echo "Keyserver <$keyserver> is already installed"
     else
          echo "Install Keyserver <$keyserver> onto $device2 LUKS Header"
          echo $password | clevis luks bind -d $device2-part4 tang "{\"url\": \"http://$keyserver\" , \"adv\": \"/tmp/keyserver-$counter.jws\" }"
     fi

     # Increment counter
     counter=$((counter+1))
done

# Clear password from memory
unset $password


# Update initramfs
update-initramfs -c -k all

# Get information
cryptsetup luksDump $device1-part4
cryptsetup luksDump $device2-part4
clevis luks list -d $device1-part4
clevis luks list -d $device2-part4
