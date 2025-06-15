#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

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

# Get OS Family
get_os_family() {
    # The Distribution can be Detected by looking at the Line starting with ID=...
    # Possible values: ID=fedora, ID=debian, ID=ubuntu, ...
    distribution=$(cat /etc/os-release | grep -Ei "^ID_LIKE=" | sed -E "s|ID_LIKE=([a-zA-Z]+?)|\1|")

    # If nothing was found, use simply the "ID" Property directly using get_os_release
    if [[ -z "${distribution}" ]]
    then
        distribution=$(get_os_release)
    fi

    # Return Value
    echo $distribution
}

# Update GRUB Configuration
update_grub_configuration() {
    if [[ $(get_os_release) == "fedora" ]]
    then
        grub2-mkconfig -o /boot/grub2/grub.cfg
    elif [[ $(get_os_release) == "debian" ]]
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

    if [[ $(get_os_family) == "fedora" ]]
    then
        grub2-probe "${ltarget}"
    elif [[ $(get_os_family) == "debian" ]]
    then
        grub-probe "${ltarget}"
    fi
}

grub_install() {
    # Input Arguments
    local loptions="$@"

    if [[ $(get_os_family) == "fedora" ]]
    then
        grub2-install ${loptions}
    elif [[ $(get_os_family) == "debian" ]]
    then
        grub-install ${loptions}
    fi
}

# Update Initrd
regenerate_initrd() {
    # Input Arguments
    local lforce=${1-"no"}

    if [[ $(get_os_family) == "fedora" ]]
    then
        dracut --regenerate-all --force
    elif [[ $(get_os_release) == "debian" ]]
    then
        update-initramfs -k all -u
    fi
}

# Update Lists
update_lists() {
    # Input Arguments
    local lpackages=$@

    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get update
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf update --refresh
    fi
}

# Install Packages
install_packages() {
    # Input Arguments
    local lpackages=$@

    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get install ${lpackages[*]}
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf install ${lpackages[*]}
    fi
}

# Install Packages (unattended)
install_packages_unattended() {
    # Input Arguments
    local lpackages=$@

    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get install --yes ${lpackages[*]}
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf install -y ${lpackages[*]}
    fi
}

# Remove Packages
remove_packages() {
    # Input Arguments
    local lpackages=$@

    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get remove ${lpackages[*]}
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf remove ${lpackages[*]}
    fi
}

# Remove Packages (unattended)
remove_packages_unattended() {
    # Input Arguments
    local lpackages=$@

    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get remove --yes ${lpackages[*]}
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf remove -y ${lpackages[*]}
    fi
}

# Purge Packages
purge_packages() {
    # Input Arguments
    local lpackages=$@

    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get purge ${lpackages[*]}
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf remove ${lpackages[*]}
    fi
}

# Purge Packages (unattended)
purge_packages_unattended() {
    # Input Arguments
    local lpackages=$@

    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get purge --yes ${lpackages[*]}
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf remove -y ${lpackages[*]}
    fi
}

# Autoremove Packages
autoremove_packages() {
    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get autoremove
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf autoremove
    fi
}


# Upgrade Packages
upgrade_packages() {
    # Get OS Family
    distribution_family=$(get_os_family)

    if [[ "${distribution_family}" == "debian" ]]
    then
        apt-get dist-upgrade
    elif [[ "${distribution_family}" == "fedora" ]]
    then
        dnf upgrade
    fi
}

# Wait until Device becomes available
wait_until_device_becomes_available() {
    # Input Arguments
    local ldevice="$1"
    local lsleep=${2-"1"}
    local ltimeout=${3-"10"}

    # Define Counter for Timeout
    local lwaitcounter
    lwaitcounter=0

    # Define Counter Step
    local lwaitstep=0.2

    # Standard Sleep
    sleep "${lsleep}"

    # Wait until Device becomes available or Timeout is reached
    while [[ ${lwaitcounter} -le ${ltimeout} ]]
    do
        # Wait a bit
        sleep "${lwaitstep}"

        # Increase Waiting Counter
        lwaitcounter=$(echo "scale=3; ${lwaitcounter} + ${lwaitstep}" | bc)

        # Check if Device exists
        if [[ -e "${ldevice}" ]]
        then
            break
        fi
    done

    # Final Check if Device exists
    if [[ -e "${ldevice}" ]]
    then
        return 0
    else
        echo "ERROR: Device ${ldevice} does not Exist ! Aborting Execution !"
        exit 1
    fi
}