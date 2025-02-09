#!/bin/bash

# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load configuration
source $toolpath/load.sh

# Source: https://support.cpanel.net/hc/en-us/articles/1500012454701-How-To-Find-The-List-Of-All-The-Chroot-ed-Processes-On-The-System
# for file in `find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null`; do PID=`ls -d $file 2> /dev/null| awk -F "/" '{print $3}'` && printf "%s = %s = %s\n" "$PID" `ps -p "$PID" 2> /dev/null | tail -n1 | awk '{print $4}'` `readlink $file 2> /dev/null` | grep -Eiv "(= /$|^\s*=\s*$|^.*?=\s*$)";done
#for file in `find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null`
#do
#PID=`ls -d $file 2> /dev/null| awk -F "/" '{print $3}'` && printf "%s = %s = %s\n" "$PID" `ps -p "$PID" 2> /dev/null | tail -n1 | awk '{print $4}'` `readlink $file 2> /dev/null` | grep -Eiv "(= /$|^\s*=\s*$|^.*?=\s*$)"
#done

# https://support.cpanel.net/hc/en-us/articles/1500012454701-How-To-Find-The-List-Of-All-The-Chroot-ed-Processes-On-The-System
#echo "USING INITIAL SOLUTION"
#for file in `find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null`
#do
#    PID=`ls -d $file 2> /dev/null| awk -F "/" '{print $3}'` && printf "%s = %s = %s\n" "$PID" `ps -p "$PID" 2> /dev/null | tail -n1 | awk '{print $4}'` `readlink $file 2> /dev/null` | grep -Eiv "(= /$|^\s*=\s*$|^.*?=\s*$)"
#
#    # Echo
#    echo "Found File ${file} used by Process ID ${PID}"
#done

# Using mapfile
#echo "USING MAPFILE"
#mapfile files < <(find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null)
#for file in "${files[@]}"
#do
#    # Find Associated PID
#    PID=`ls -d $file 2> /dev/null | awk -F "/" '{print $3}'`
#    FILE_FILTERED=$(echo "$file" | head -n1)
#    INFO_FILTERED=$(printf "%s = %s = %s\n" "$PID" `ps -p "$PID" 2> /dev/null | tail -n1 | awk '{print $4}'` `readlink $file 2> /dev/null` | grep -Eiv "(= /$|^\s*=\s*$|^.*?=\s*$)")
#    PROCESS_FILTERED=
#
#    # Echo
#    if [[ -n "${INFO_FILTERED}" ]]
#    then
#        # Echo
#        echo "Found File ${FILE_FILTERED} used by Process ID ${PID_FILTERED}"
#
#        # Kill it
#        # kill -9 $PID
#    fi
#done


# Find all Processes running in the Chroot
mapfile files < <(find /proc/ -type l -name "root" -print 2> /dev/null | grep -Eiv /task/ 2> /dev/null)
for file in "${files[@]}"
do
    # Find Associated PID
    PID=`ls -d $file 2> /dev/null | awk -F "/" '{print $3}'`
    FILE_FILTERED=$(echo "$file" | head -n1)
    INFO_FILTERED=$(printf "%s;%s;%s\n" "$PID" `ps -p "$PID" 2> /dev/null | tail -n1 | awk '{print $4}'` `readlink $file 2> /dev/null` | grep -Eiv "(;/$|^\s*;\s*$|^.*?;\s*$)")
    IFS=';' read -ra INFO_SPLIT <<< "$INFO_FILTERED"; unset IFS

    # Echo
    if [[ -n "${INFO_FILTERED}" ]]
    then
        # Extract Other Information
        PROCESS_NAME="${INFO_SPLIT[1]}"

        # Echo
        echo "Found File ${FILE_FILTERED} used by Process ID ${INFO_FILTERED}"
        echo "Other Info: PID = ${PID} , Process Name = ${PROCESS_NAME}"

        # Kill Process
        kill -9 $PID
    fi
done
