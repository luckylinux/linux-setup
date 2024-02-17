#!/bin/bash

# If toolpath not set, set it to current working directory
if [[ ! -v toolpath ]]
then
    toolpath=$(pwd)
fi

# Load configuration
source $toolpath/config.sh

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
