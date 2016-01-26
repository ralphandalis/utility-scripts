#! /usr/bin/bash

# This is a simple bash script for running the iphonessh python-client
# in just one command execution. 
# This is just for my convenience. 

# directory of the iphonessh repo where it is cloned
dir="/Users/ralphnicoleandalis/iphonessh/python-client"
cd "$dir"
# this code is problematic, causes log when run
# open -a Terminal run_script.sh
echo -e "Type the following command in the open terminal: "
echo -e "COMMAND: 'ssh root@localhost -p 2222'"
open -a Terminal $dir

# this code is problematic
# && `bash run_script.sh`
python tcprelay.py -t 22:2222