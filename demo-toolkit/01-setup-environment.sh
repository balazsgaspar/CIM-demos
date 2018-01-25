#!/bin/bash
# Usage:  "sudo ./00-setup-environment.sh"
source functions.sh

# Change back to [n]o!
use_aws_credentials='y'
use_aws_config='y'
accessKeyId=''
secretAccessKey=''
check_director_scripts

#check_aws_configuration
if [ "$use_aws_credentials" != "y" ]; then
    read -p 'AWS accessKeyId: ' accessKeyId
    read -sp 'AWS secretAccessKey: ' secretAccessKey
    printf '\n'
else
   printf "Using existing AWS credentials.\n"
fi 

#read -p 'Director bootstrap config to use: ' bootstrap
bootstrap='sample.conf'

check_python_env
read_aws_configuration

# We can write/update the AWS config and credential files
write_aws_configuration

# Validate key name
printf 'Validating key \"%s\" in region %s... ' $aws_keyname $aws_region
json=$(aws ec2 describe-key-pairs --key-name $aws_keyname 2>/dev/null )

if [ "$json" != "" ]; then
    printf "Done\n"
else
    printf "Error, key not found!\n"
fi

bootstrap2json $bootstrap
