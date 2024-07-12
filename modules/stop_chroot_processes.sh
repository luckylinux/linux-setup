#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/config.sh

# Source: https://support.cpanel.net/hc/en-us/articles/1500012454701-How-To-Find-The-List-Of-All-The-Chroot-ed-Processes-On-The-System
# for file in `find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null`; do PID=`ls -d $file 2> /dev/null| awk -F "/" '{print $3}'` && printf "%s = %s = %s\n" "$PID" `ps -p "$PID" 2> /dev/null | tail -n1 | awk '{print $4}'` `readlink $file 2> /dev/null` | grep -Eiv "(= /$|^\s*=\s*$|^.*?=\s*$)";done
#for file in `find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null`
#do
#PID=`ls -d $file 2> /dev/null| awk -F "/" '{print $3}'` && printf "%s = %s = %s\n" "$PID" `ps -p "$PID" 2> /dev/null | tail -n1 | awk '{print $4}'` `readlink $file 2> /dev/null` | grep -Eiv "(= /$|^\s*=\s*$|^.*?=\s*$)"
#done

# List Processes running in Chroot
mapfile files < <(find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null)
for file in "${files[@]}"
do
    # Find Associated PID
    PID=`ls -d $file 2> /dev/null | awk -F "/" '{print $3}'`

    # Echo
    echo "Found File ${file} used by Process ID ${PID}"

    # Kill Process
    kill -9 $PID
done
