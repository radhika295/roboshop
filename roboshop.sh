#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-045897fa6d8ffd258"

for instance in $@
do
    Instance_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instnace}]" --query 'Instances[0].InstanceId' --output text)
    if [ $instance != "frontend" ]; then
        Private_Ip=$(aws ec2 describe-instances --instance-ids $Instance_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
         Private_Ip=$(aws ec2 describe-instances --instance-ids $Instance_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi

    echo $instance:$Private_Ip    
done
