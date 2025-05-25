#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source "${toolpath}/load.sh"

# If mountpoint doesn't exist we must create it
mkdir -p ${destination}

# Check if mountpoint is non-empty
if [ -z "$(ls -A ${destination})" ]; then
   # Nothing to do
   x=1
else
   echo "ERROR: Mointpoint ${destination} is NOT Empty"
   echo "ABORTING DUE TO CRITICAL ERROR"
   exit 9
fi

# Ensure that a Filesystem is mounted there
chattr +i ${destination}
