#!/bin/bash

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