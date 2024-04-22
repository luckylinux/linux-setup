#!/bin/bash

# Make sure we are in chroot
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]
then
	# In Chroot Enviroment, $destination must be set to ""
	destination=""

        # In Chroot Environment, $installroot must also be set to ""
        installroot=""
fi

