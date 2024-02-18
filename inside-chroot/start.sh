#!/bin/bash

# Used if we can run directly a script when entering chroot
# So that the user doesn't need to manually source /etc/profile within the chroon and
# cd to /tools_install/$timestamp

# Determine toolpath
#scriptpath=$(dirname "${BASH_SOURCE[0]}")
#parentpath=$(dirname "$scriptpath")
#toolpath1="$( cd "$( dirname "$scriptpath" )" > /dev/null && pwd )"
scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
toolpath=$(realpath --canonicalize-missing $scriptpath/..)


echo "Script path: $scriptpath"

# Relativefolder
#relativefolder=".."

# Need to strip first $0 of ./
#arg=$0
#arg=${arg//.\//""}

# Determine subfolder based on script invocation call
#subfolder=$(dirname $arg)

#relativepath=$(dirname $relativefolder/$arg)
#relativepath=$(realpath --canonicalize-missing ${relativepath})

# Remove subfolder name if present in name
#toolpath2=$(realpath --canonicalize-missing ${relativepath//${subfolder}/""})

# Return shortest string
#if [ ${#toolpath1} -lt ${#toolpath2} ]; then toolpath=$toolpath1; else toolpath=$toolpath2; fi
echo "Tool path: $toolpath"


# Make sure we are in chroot
# Abort if we are trying to run the script from the host machine
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]
then
        echo "This script must ONLY be run within the chroot environment. Aborting !"
        exit 2
fi

echo "Starting script"

# Load Configuration
source $toolpath/config.sh

# Load default Shell Profile
source /etc/profile

# Change Directory
cd /tools_install/$timestamp

# Return
return
