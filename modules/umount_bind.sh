#!/bin/bash

# Load configuration
source config.sh

# Umount proc
mount --make-rslave "${destination}/proc"
umount -R "${destination}/proc"

# Umount sys
mount --make-rslave "${destination}/sys"
umount -R "${destination}/sys"

# Umount dev
mount --make-rslave "${destination}/dev"
umount -R "${destination}/dev"
