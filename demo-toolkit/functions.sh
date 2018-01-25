#!/bin/bash

# Performs basic checks to verify that director-scripts has been cloned locally
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

# Check if required Python packages are present
function check_python_env {
    pyhocon="$(pip freeze | grep pyhocon)"
    #pyhocon_version=${#pyhocon}
    #echo $pyhocon_version
    
    if [ -z "$pyhocon" ]
    then
        read -p "pyhocon python package is required, but is not installed. Install now? [y/n]: " install_pyhocon
        if [ "$install_pyhocon" = "y" ]; then
            printf "Installing pyhocon... \n"
            # We use pyhocon to parse HOCON config files (used in Director bootstrap script) and to convert HOCON to JSON
            # https://github.com/chimpler/pyhocon
            pip install pyhocon -q
        else
            printf "Exiting... \n"
            exit
        fi
    else
        printf "Found following pyhocon version: %s \n" $pyhocon
    fi
}

function bootstrap2json {
    # Exporting AWS credentials as environment variables
    # These are valid for the scope of the bash script only and will NOT be set in the user's bash session
    export AWS_ACCESS_KEY_ID=$(grep "aws_access_key_id" < ~/.aws/credentials | grep -o "[^=]*$") 
    export AWS_SECRET_ACCESS_KEY=$(grep "aws_secret_access_key" < ~/.aws/credentials | grep -o "[^=]*$") 

    if [ -z "$1" ]; then
        printf "ERROR: 1 argument required, $# provided. Exiting... \n"
        exit
    else
        printf "Creating json file from bootstrap script [$1 -> director.json]... \n"
        # TODO: Uncomment this - needed to convert HOCON to JSON
        pyhocon -i $1 -o director.json -f json    
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

# Checks if AWS credentials and AWS configuration file exists locally (AWS parameters have been entered previously)
function check_aws_configuration {
    AWS_CONF_DIR="$HOME/.aws"
    printf "Looking for AWS credentials and configuration file at %s ... \n" $AWS_CONF_DIR
    if [ -d $AWS_CONF_DIR ]; then
        if [ "$AWS_CONF_DIR/credentials" ]; then
            printf "AWS credentials already provided.\n"
            # read -p 'Use existing credentials file? [y/n]: ' use_aws_credentials
            # TODO: Print configured access_key to the console
        fi
        if [ "$AWS_CONF_DIR/config" ]; then
            printf "AWS configuration already provided.\n"
            # read -p 'Use existing configuration file? [y/n]: ' use_aws_config
            # TODO: Dump configuration to the console
        fi
    fi
    
    #printf "Setting AWS credentials as local variables... \n"
    #while read -r line; do declare  $line; done <~/.aws/credentials
    #while read -r line; do declare  ${line^^}; done <~/.aws/credentials
    #export AWS_ACCESS_KEY_ID=AKIAINKLRJCNG5LUY5UA
    #echo $aws_access_key_id
    #echo $AWS_ACCESS_KEY_ID
}

function read_aws_configuration {
    # Read environment configuration from bootstrap script (and strip leading/trailing quotes)
    aws_region=$(jq ".provider.region" director.json)
    aws_region=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_region")
    aws_keyname=$(jq ".provider.keyName" director.json)
    aws_keyname=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_keyname")
    # Idea taken from https://stackoverflow.com/questions/9733338/shell-script-remove-first-and-last-quote-from-a-variable
    
    printf 'AWS region: %s\n' $aws_region
    printf 'AWS key pair name: %s\n' $aws_keyname
}

# Creates / overwrites AWS credentials and AWS configuration file
function write_aws_configuration {
    AWS_CONF_DIR="$HOME/.aws"
    #printf "%s \n" $AWS_CONF_DIR
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
