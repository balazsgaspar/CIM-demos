#!/bin/bash
# Usage:  "sudo ./00-setup-environment.sh"

function check_director_scripts {
    DIRECTOR_SCRIPTS_DIR="$HOME/director-scripts"
    #printf "%s \n" $DIRECTOR_SCRIPTS_DIR
    if [ -d $DIRECTOR_SCRIPTS_DIR ]; then
        printf "Using director-scripts directory found at %s\n" $DIRECTOR_SCRIPTS_DIR
    else
        printf "director-scripts directory not found! Please clone from GitHub:\n"
        printf "git clone https://github.com/cloudera/director-scripts.git"
    fi
}

function list_fb_supported_regions {
    # List regions supported for faster-bootstrap
    REGIONS_LIST="$DIRECTOR_SCRIPTS_DIR/faster-bootstrap/scripts/building"
    #printf "$REGIONS_LIST\n";
    if [ -d $REGIONS_LIST ]; then
        printf "Using regions directory found at %s\n" $REGIONS_LIST
        for entry in $REGIONS_LIST/*
            do
              echo ${entry##*/}
            done
    else
        printf "No regions configuration file! Please validate or update your director-scripts!\n"
    fi
}

function check_aws_configuration {
    AWS_CONF_DIR="$HOME/.aws"
    printf "%s \n" $AWS_CONF_DIR
    if [ -d $AWS_CONF_DIR ]; then
        if [ "$AWS_CONF_DIR/credentials" ]; then
            printf "AWS credentials already provided.\n"
            read -p 'Use existing credentials file? [y/n]: ' use_aws_credentials
        fi
        if [ "$AWS_CONF_DIR/config" ]; then
            printf "AWS configuration already provided.\n"
            read -p 'Use existing configuration file? [y/n]: ' use_aws_config
        fi
    fi
    
}

function write_aws_configuration {
    AWS_CONF_DIR="$HOME/.aws"
    printf "%s \n" $AWS_CONF_DIR
    if [ -d $AWS_CONF_DIR ]; then
        printf "Found AWS config directory.\n"
    else
        printf "Creating AWS config directory... "
        mkdir $AWS_CONF_DIR
        printf "Done\n"
    fi
    if [ "$use_aws_credentials" != "y" ]; then
        printf "Writing AWS credentials file... "
        printf "[default]\naws_access_key_id=$accessKeyId\naws_secret_access_key=$secretAccessKey" > "$AWS_CONF_DIR/credentials"
        printf "Done\n"
    fi
    if [ "$use_aws_config" != "y" ]; then
        printf "Writing AWS config file... "
        printf "[default]\nregion=$aws_region\noutput=json" > "$AWS_CONF_DIR/config"
        printf "Done\n"
    fi
    # TODO: Alternatively, write the config file using amazon configure
    # http://docs.aws.amazon.com/cli/latest/reference/configure/set.html
    
    # TODO: Use "aws configure list" to validate the configuration
    
}

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

read -p 'Director bootstrap config to use: ' bootstrap


# We use pyhocon to parse HOCON config files (used in Director bootstrap script) and to convert HOCON to JSON
# https://github.com/chimpler/pyhocon
pip install pyhocon -q

# TODO: Uncomment this - needed to convert HOCON to JSON
pyhocon -i $bootstrap -o director.json -f json

# Read environment configuration from bootstrap script (and strip leading/trailing quotes)
aws_region=$(jq ".provider.region" director.json)
aws_region=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_region")
aws_keyname=$(jq ".provider.keyName" director.json)
aws_keyname=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_keyname")
# Idea taken from https://stackoverflow.com/questions/9733338/shell-script-remove-first-and-last-quote-from-a-variable

printf 'AWS region: %s\n' $aws_region
printf 'AWS key pair name: %s\n' $aws_keyname

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
