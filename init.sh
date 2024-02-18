#!/bin/bash

# This file MUST be SOURCED as in `source init.sh`.
# Calling with file as in `./init.sh` or `bash init.sh` will NOT work, as the variable $toolpath will be otherwise deleted at the end of the script execution !

# This file MUST be called before ANY other file, to make sure that the path of the tool is correctly set
# This is the easiest way to set the $toolpath variable once and for all
toolpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

