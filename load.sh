#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Files in config-pre/ folder
for f in $toolpath/config-pre/*.sh
do
    source $f
done

# Load User Configuration
if [[ -f "$toolpath/config.sh" ]]
then
    source $toolpath/config.sh
else
    echo "Configuration File $toolpath/config.sh does NOT exist !"
fi

# Load files in config-post/ folder
for f in $toolpath/config-post/*.sh
do
    source $f
done
