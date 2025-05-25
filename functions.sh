#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load config
# Do **NOT** use load.sh here, since it will create an Infitite Loop
source "${toolpath}/config.sh"

# Get OS Release
get_os_release() {
    # The Distribution can be Detected by looking at the Line starting with ID=...
    # Possible values: ID=fedora, ID=debian, ID=ubuntu, ...
    distribution=$(cat /etc/os-release | grep -Ei "^ID=" | sed -E "s|ID=([a-zA-Z]+?)|\1|")

    # Return Value
    echo $distribution
}

# Get OS Codename
get_os_codename() {
    # The Distribution can be Detected by looking at the Line starting with ID=...
    # Possible values: VERSION_CODENAME=bookworm, VERSION_CODENAME=trixie, VERSION_CODENAME=mantic, VERSION_CODENAME=noble, ...
    codename=$(cat /etc/os-release | grep -Ei "^VERSION_CODENAME=" | sed -E "s|VERSION_CODENAME=([a-zA-Z]+?)|\1|")

    # Return Value
    echo $codename
}

# Get EFI Mount Path
get_efi_mount_path() {
    # Input Arguments
    local ldisk="$1"

    if [[ "${numdisks_total}" -eq 1 ]]
    then
        efi_mount_path="/boot/efi"
    else
        efi_mount_path="/boot/efi/${ldisk}"
    fi

    # Return Value
    echo "${efi_mount_path}"
}