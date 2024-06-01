#!/bin/bash

# Current Host Name
oldname=$(hostname)

# New Host Name
read -p "New Host Name: " newname

# Convert to Lowercase
newname=${newname,,}

# Echo
echo "Changing hostname from <${oldname}> to <${newname}> for System"

# Temporarily Update Hostname (before reboot)
hostname $newname

# Update Shell $HOSTNAME Variable
export HOSTNAME="$newname"

# Perform Name Substitution
sed -i "s/$oldname/$newname/g" /etc/hosts
sed -i "s/$oldname/$newname/g" /etc/hostname
sed -i "s/$oldname/$newname/g" /etc/mailname
sed -i "s/$oldname/$newname/g" /etc/salt/minion_id
sed -i "s/$oldname/$newname/g" /etc/exim4/update-exim4.conf.conf
sed -i "s/$oldname/$newname/g" /etc/hosts

# Regenerate SSH Keys
# Delete old keys
rm -v /etc/ssh/ssh_host_*

dpkg-reconfigure openssh-server
systemctl restart ssh

# Restart SSH service
systemctl restart sshd
systemctl restart ssh

# Generate new Machine ID
rm -f /etc/machine-id /var/lib/dbus/machine-id
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure

# Remove duid from dhcp if it exists
if [[ -d "/var/lib/dhcpcd" ]]
then
   rm -f /var/lib/dhcpcd/duid
   rm -f /var/lib/dhcpcd/*.lease
   rm -f /var/lib/dhcpcd/*.lease6
fi
