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

# Chroot into the environment
chroot "${destination}" /bin/bash --login
#chroot "${destination}" /bin/bash --login -c "/bin/bash /tools_install/$timestamp/inside-chroot/start.sh"
#-x  <<'EOF'
#source /etc/profile
#cd /tools_install/$timestamp
#EOF
