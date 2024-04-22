# Hetzner ZFS Fix
# This will remove their /usr/local/sbin/zfs dummy Package since we install directly from Debian Backports
if [[ "$hetznerzfsfix" == "yes" ]]
then
   if [[ -f "/usr/local/sbin/zfs" ]]
   then
      #chattr -i /usr/local/sbin/zfs
      #rm -f /usr/local/sbin/zfs

      echo "Please Close your SSH Session Now and Login Again"
      echo "This is required to remove all References to the old /usr/local/sbin/zfs alias"

      #exit 9
   fi

   # Load default Profile from the Distribution
   source /etc/skel/.bashrc

   # Disable weird Echo
   shopt -u progcomp
   shopt -u extdebug
   shopt -u xpg_echo

   # Make sure that PATH does NOT include stuff from /usr/local/bin and /usr/local/sbin
   export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
fi
