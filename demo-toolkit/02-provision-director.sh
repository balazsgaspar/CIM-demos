#!/bin/bash

#aws configure list

aws_cm_ami=$(jq '."cloudera-manager".instance.image' director.json)
aws_cm_ami=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_cm_ami")
aws_director_ami=$aws_cm_ami
aws_director_instance_type='c4.large' 
# See requirements: https://www.cloudera.com/documentation/director/latest/topics/director_deployment_requirements.html

aws_keyname=$(jq ".provider.keyName" director.json)
aws_keyname=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_keyname")
aws_director_keyname=$aws_keyname

aws_security_group=$(jq ".provider.securityGroupsIds" director.json)
aws_security_group=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_security_group")
aws_director_security_group=$aws_security_group

aws_subnet=$(jq ".provider.subnetId" director.json)
aws_subnet=$(sed -e 's/^"//' -e 's/"$//' <<<"$aws_subnet")
aws_director_subnet=$aws_subnet

# aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids sg-xxxxxxxx --subnet-id subnet-xxxxxxxx
command_launch_director="aws ec2 run-instances --image-id $aws_director_ami --count 1 --instance-type $aws_director_instance_type --key-name $aws_director_keyname --security-group-ids $aws_director_security_group --subnet-id $aws_director_subnet"

#command_list_instances="aws ec2 describe-instances"
#instance_list="$($command_list_instances)"
#echo $instance_list | jq ".Reservations[0]"

printf "Starting director instance with command \'$command_launch_director\'\n"

director_instance_json=$($command_launch_director)
 #TODO: Implement error handling"
instance_id=$(echo $director_instance_json | jq .Instances[0].InstanceId)
instance_id=$(sed -e 's/^"//' -e 's/"$//' <<<"$instance_id")

printf "Director instance launched with instance_id %s\n" $instance_id

printf "Adding name and owner tags to instance_id %s\n" $instance_id
command_add_tags="aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=Balazs_Director Key=Owner,Value=balazs"
tags_result=$($command_add_tags)
echo $tags_result
#TODO: Implement error handling"

printf "Following tags were added:\n"
instance_tags_json=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance_id")
echo $instance_tags_json | jq .

# Waiting for instance to enter 'running' state

instance_state=0
while [ $instance_state != "16" ]
do
    printf "Director instance is still starting up. Waiting 5 seconds... \n"
    instance_json=$(aws ec2 describe-instances --instance-ids $instance_id)
    instance_state_code=$(echo $instance_json | jq .Reservations[0].Instances[0].State.Code)
    instance_state_code=$(sed -e 's/^"//' -e 's/"$//' <<<"$instance_state_code")

    instance_state_name=$(echo $instance_json | jq .Reservations[0].Instances[0].State.Name)
    instance_state_name=$(sed -e 's/^"//' -e 's/"$//' <<<"$instance_state_name")
        
    #printf "Instance state is \'%s\' with code %s. \n" $instance_state_name $instance_state_code
    instance_state=$instance_state_code 
    sleep 5
done
printf "Director instance is ready! \n"
    