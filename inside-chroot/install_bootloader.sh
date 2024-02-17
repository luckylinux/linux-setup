#!/bin/bash

# Install GRUB to MBR
if [ "$bootloadermode" == "BIOS" ]
then
    # Install GRUB
    apt-get install --yes grub-pc

    # BIOS
    grub-install "${device1}"
    grub-install "${device2}"
elif [ "$bootloadermode" == "UEFI" ]
then
    # Install GRUB
    apt-get install --yes grub-efi-amd64

    # UEFI
    grub-install --target=x86_64-efi "${device1}"
    grub-install --target=x86_64-efi "${device2}"
    #grub-install --target=x86_64-efi --efi-directory=/boot/efi \
    #--bootloader-id=ubuntu --recheck --no-floppy
else
    # Not Supported
    echo "Error - bootloadermode <${bootloadermode}> is NOT supported. Aborting"
    exit 1
fi

# Update initramfs
update-initramfs -k all -u

# Update GRUB configuration
update-grub

