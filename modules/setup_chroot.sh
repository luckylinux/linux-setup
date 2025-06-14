#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Bind required filesystems
source ${toolpath}/modules/mount_bind.sh

# Copy tool to chroot folder
source ${toolpath}/modules/copy_tool_to_chroot.sh

# Configure /etc/resolv.conf
if [[ -L "${destination}/etc/resolv.conf" ]]
then
    # Get Symlink Destination
    real_file=$(readlink --canonicalize-missing "${destination}/etc/resolv.conf")

    if [[ ! -f "${real_file}" ]]
    then
        # Echo
        echo "${destination}/etc/resolv.conf points to ${real_file}, but it does **NOT** Exists"

        # Moving Symlink to /etc/resolv.conf.systemd
        mv "${destination}/etc/resolv.conf" "${destination}/etc/resolv.conf.systemd"

        # Link directly to real path of /etc/resolv.conf
        # host_resolv=$(realpath --canonicalize-missing "/etc/resolv.conf")
        # ln -s "${host_resolv}" "${destination}/etc/resolv.conf"

        # Copy Contents to /etc/resolv.conf
        host_resolv=$(realpath --canonicalize-missing "/etc/resolv.conf")
        cat "${host_resolv}" > "${destination}/etc/resolv.conf"
    fi
fi

# Chroot into the environment
chroot "${destination}" /bin/bash --login
#chroot "${destination}" /bin/bash --login -c "/bin/bash /tools_install/$timestamp/inside-chroot/start.sh"
#-x  <<'EOF'
#source /etc/profile
#cd /tools_install/$timestamp
#EOF
