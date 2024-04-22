# Determine toolpath if not set already
relativepath="../" # Define relative path to go from this script to the root level of the tool
if [[ ! -v toolpath ]]; then scriptpath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ); toolpath=$(realpath --canonicalize-missing $scriptpath/$relativepath); fi

# Load Configuration
source $toolpath/config.sh

# Create file /etc/rc.local if it doesn't exist yet
if [ ! -f ${destination}/etc/rc.local ]
then
	cp ${toolpath}/files/etc/rc.local.default ${installroot}/etc/rc.local
fi

# At the very least make sure to execute dhclient -v on line number 2 (after the Shebang)
sed -i '2i dhclient -v' ${installroot}/etc/rc.local

# Make it executable
chmod +x ${destination}/etc/rc.local

# Create Systemd service to enable /etc/rc.local
mkdir -p ${destination}/etc
mkdir -p ${destination}/etc/systemd
mkdir -p ${destination}/etc/systemd/system
cp ${toolpath}/files/etc/systemd/system/rc-local.service ${installroot}/etc/systemd/system/rc-local.service

# Enable & start service
systemctl enable rc-local.service
systemctl start rc-local.service
systemctl status rc-local.service
