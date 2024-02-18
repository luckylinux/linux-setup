#!/bin/bash

# This file MUST be called before ANY other file, to make sure that the path of the tool is correctly set
# This is the easiest way to set the $toolpath variable once and for all
export toolpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
