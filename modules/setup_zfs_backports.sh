#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

if [[ "${DISTRIBUTION_FAMILY}" == "debian" ]]
then
   # Get Debian Version
   echo "Configuring System <${distribution} ${release}> to use Backports Packages for ZFS"

   # Create folder if not exist
   mkdir -p ${installroot}/etc
   mkdir -p ${installroot}/etc/apt
   mkdir -p ${installroot}/etc/apt/sources.list.d
   mkdir -p ${installroot}/etc/apt/preferences.d

   # Copy Backports Definition
   cp ${toolpath}/repositories/${distribution}/${release}/sources.list.d/${distribution}-backports.list ${installroot}/etc/apt/sources.list.d/${distribution}-backports.list

   # By default do NOT use backports
   cp ${toolpath}/repositories/${distribution}/${release}/preferences.d/${distribution}-backports ${installroot}/etc/apt/preferences.d/${distribution}-backports


   # Also use Kernel Backports ?
   if [[ "${usekernelbackports}" == "yes" ]]
   then
      # Copy Kernel Backports Configuration
      cp ${toolpath}/repositories/${distribution}/${release}/preferences.d/kernel-backports ${installroot}/etc/apt/preferences.d/kernel-backports
   fi

   # Copy ZFS Backports Configuration
   cp ${toolpath}/repositories/${distribution}/${release}/preferences.d/zfs-backports ${installroot}/etc/apt/preferences.d/zfs-backports

   # Update Sources
   update_lists

   # Perform Installation
   install_packages zfsutils-linux zfs-dkms

   # Upgrade Kernel Packages if applicable
   upgrade_packages
fi