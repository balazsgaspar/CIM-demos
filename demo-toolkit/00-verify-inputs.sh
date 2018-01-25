#!/bin/bash
source functions.sh

# Change back to [n]o!
use_aws_credentials='y'
use_aws_config='y'
accessKeyId=''
secretAccessKey=''

check_director_scripts
check_aws_configuration
check_python_env

#bootstrap2json "sample.conf"
#read_aws_configuration
