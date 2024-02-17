#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

# Bind required filesystems
source $toolpath/modules/mount_bind.sh

# Copy tool to chroot folder
source $toolpath/modules/copy_tool_to_chroot.sh

# Chroot into the environment
chroot "${destination}" /bin/bash --login
#chroot "${destination}" /bin/bash --login -c "/bin/bash /tools_install/$timestamp/inside-chroot/start.sh"
#-x  <<'EOF'
#source /etc/profile
#cd /tools_install/$timestamp
#EOF
