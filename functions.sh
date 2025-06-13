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

# Get OS Version
get_os_version() {
    # The Distribution can be Detected by looking at the Line starting with ID=...
    # Possible values: VERSION_CODENAME=bookworm, VERSION_CODENAME=trixie, VERSION_CODENAME=mantic, VERSION_CODENAME=noble, ...
    codename=$(cat /etc/os-release | grep -Ei "^VERSION_ID=" | sed -E "s|VERSION_ID=\"([0-9\.]+?)\"|\1|")

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

# Update GRUB Configuration
update_grub_configuration() {
    if [[ $(get_os_release) == "fedora" ]]
    then
        grub2-mkconfig -o /boot/grub2/grub.cfg
    elif [[ $(get_os_release) == "debian"" ]]
    then
        update-grub
    elif [[ $(get_os_release) == "ubuntu" ]]
    then
        upgrade-grub
    fi
}

# Force GRUB Rescan of Partition Layouts and UUIDs
force_grub_configuration_update_after_partition_changes() {
    if [[ $(get_os_release) == "fedora" ]]
    then
        # Remove Configuration
        rm /boot/grub2/grub.cfg

        # Reinstall all GRUB Packages
        dnf reinstall shim-* grub2-efi-* grub2-common

        # Remove all Files in /boot/loader/entries/*.conf, then reinstall kernel-core to Trigger GRUB update to use new Partition Layout
        if [[ -d /boot/loader/entries ]]
        then
            rm -rf /boot/loader/entries/*
            dnf reinstall kernel-core
        fi
    fi
}

# Probe GRUB Partition
grub_probe() {
    # Input Arguments
    local ltarget="$1"

    if [[ $(get_os_release) == "fedora" ]]
    then
        grub2-probe "${ltarget}"
    elif [[ $(get_os_release) == "debian"" ]]
    then
        grub-probe "${ltarget}"
    elif [[ $(get_os_release) == "ubuntu" ]]
    then
        grub-probe "${ltarget}"
    fi

}

# Update Initrd
regenerate_initrd() {
    # Input Arguments
    local lforce=${1-"no"}

    if [[ $(get_os_release) == "fedora" ]]
    then
        dracut --regenerate-all --force
    elif [[ $(get_os_release) == "debian"" ]]
    then
        update-initramfs -k all -u
    elif [[ $(get_os_release) == "ubuntu" ]]
    then
        update-initramfs -k all -u
    fi

}
