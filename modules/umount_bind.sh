#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# Umount proc
if mountpoint -q "${destination}/proc"
then
	mount --make-rslave "${destination}/proc"
	umount -R "${destination}/proc"
fi

# Umount sys
if mountpoint -q "${destination}/sys"
then
	mount --make-rslave "${destination}/sys"
	umount -R "${destination}/sys"
fi

# Umount dev
if mountpoint -q "${destination}/dev"
then
	mount --make-rslave "${destination}/dev"
	umount -R "${destination}/dev"
fi
