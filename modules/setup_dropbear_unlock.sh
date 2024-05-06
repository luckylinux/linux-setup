#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Setup Dropbear for automated disk unlocking
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
apt-get update

# Install clevis on the system and add clevis to the initramfs
apt-get install --yes cryptsetup-initramfs dropbear-initramfs

# Create Folder
mkdir -p ${installroot}/root
mkdir -p ${installroot}/root/.ssh

# Copy SSH keys for dropbear and change the port
echo "################################################################################################################"
echo "## Generate an ED25519 SSH Key on your Remote (e.g. Desktop) System which you want to access this System From ##"
echo "## IMPORTANT: DO **NOT** Generate the SSH Key on this Target System !! This would be completely useless :P    ##"
echo "################################################################################################################"
echo "Run this on your Remote System:"
echo "======================================================================================================================================="
echo "======================================================================================================================================="
cat <<- \EOF
LOCALSYSTEM=$(hostname)
REMOTESYSTEM="MY_SERVER_NAME"
ssh-keygen -t ed25519 -C ${REMOTESYSTEM} -f ${HOME}/.ssh/${REMOTESYSTEM}
echo "========================================================================================================================================"
echo "Public Key Generated in ${HOME}/.ssh/${REMOTESYSTEM}.pub"
echo "Private Key Generated in ${HOME}/.ssh/${REMOTESYSTEM}"
echo "========================================================================================================================================"
RAWPUBKEY=$(cat ${HOME}/.ssh/${REMOTESYSTEM}.pub)
RENAMEDPUBKEY=$(echo "${RAWPUBKEY}" | sed -E "s|${REMOTESYSTEM}|${LOCALSYSTEM}|")
echo "RAW Public Key: ${RAWPUBKEY}"
echo "========================================================================================================================================"
echo "Renamed Public Key: ${RENAMEDPUBKEY}"
echo "========================================================================================================================================"
unset RENAMEDPUBKEY
unset RAWPUBKEY
EOF
echo "======================================================================================================================================="
echo "======================================================================================================================================="
echo -e "\n\n"

# Read User Input
echo "Enter the Public Key obtained from Running the Command (last Returned Value)"
echo "The Public Key must be in the Form: ssh-ed25519 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX MyRemoteDesktopName"
read -p "Enter the Public Key: " publickey

# Save Key in /root/.ssh/authorized_keys
echo "${publickey}" >> ${installroot}/root/.ssh/authorized_keys

# Save Key for use in initramfs by Dropbear
mkdir -p ${installroot}/etc
mkdir -p ${installroot}/etc/dropbear
mkdir -p ${installroot}/etc/dropbear/initramfs
cp /root/.ssh/authorized_keys ${installroot}/etc/dropbear/initramfs/

# Configure Dropbear Options
sed -ie "s/#DROPBEAR_OPTIONS=/DROPBEAR_OPTIONS=\"-I ${dropbearwait} -j -k -p ${dropbearport} -s\"/" ${installroot}/etc/dropbear/initramfs/dropbear.conf

# Reconfigure Dropbear to use the Custom Port
dpkg-reconfigure dropbear-initramfs

# Update initramfs
update-initramfs -c -k all
