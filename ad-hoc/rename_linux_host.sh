#!/bin/bash

# Current Host Name
oldname=$(hostname)

# New Host Name

# Attempt to use Optional Argument
newname=${1:-""}

# Ask Interactively
if [[ -z "${newname}" ]]
then
    read -p "New Host Name: " newname
fi

# Convert to Lowercase
newname=${newname,,}

# Echo
echo "Changing hostname from <${oldname}> to <${newname}> for System"

# Temporarily Update Hostname (before reboot)
hostname "${newname}"

# Use Systemd Hostnamectl
hostnamectl hostname "${newname}"

# Update Shell $HOSTNAME Variable
export HOSTNAME="${newname}"

# Perform Name Substitution
sed -i "s|${oldname}|${newname}|g" /etc/hosts
sed -i "s|${oldname}|${newname}|g" /etc/hostname
sed -i "s|${oldname}|${newname}|g" /etc/mailname
sed -i "s|${oldname}|${newname}|g" /etc/salt/minion_id
sed -i "s|${oldname}|${newname}|g" /etc/exim4/update-exim4.conf.conf
sed -i "s|${oldname}|${newname}|g" /etc/hosts

# Delete old SSH Keys
rm -v /etc/ssh/ssh_host_*

# Debian/Ubuntu: Regenerate SSH Keys
if [[ -n $(command -v dpkg-reconfigure) ]]
then
   dpkg-reconfigure openssh-server
fi

# Restart SSH Service (sshd Service)
if systemctl list-unit-files sshd.service &>/dev/null; then systemctl restart sshd; fi

# Restart SSH Service (ssh Service)
if systemctl list-unit-files ssh.service &>/dev/null; then systemctl restart ssh; fi

# Generate new Machine ID
rm -f /etc/machine-id /var/lib/dbus/machine-id
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure

# Remove duid from dhcpcp if it exists
if [[ -d "/var/lib/dhcpcd" ]]
then
   rm -f /var/lib/dhcpcd/duid
   rm -f /var/lib/dhcpcd/*.lease
   rm -f /var/lib/dhcpcd/*.lease6
fi
