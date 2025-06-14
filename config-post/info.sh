#!/bin/bash

# Determine toolpath if not set already
relativepath="./" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Functions
source "${toolpath}/functions.sh"

# Define Distribution Properties Variables
export DISTRIBUTION_RELEASE=$(get_os_release)
export DISTRIBUTION_FAMILY=$(get_os_family)
export DISTRIBUTION_CODENAME=$(get_os_codename)
export DISTRIBUTION_VERSION=$(get_os_version)

# Define the current running System Distribution
# Used if need to setup Backports prior to running Install
hostdistribution=$(lsb_release -i | sed -E "s|.*?Distributor ID:\s*?([a-zA-Z]+)|\L\1|")
hostrelease=$(lsb_release -c | sed -E "s|.*?Codename:\s*?([a-zA-Z]+)|\L\1|")