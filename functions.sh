#!/bin/bash

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
