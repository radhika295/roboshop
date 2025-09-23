#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-045897fa6d8ffd258"
ZONE_ID="Z07503961RHS7OI25U00O"
DOMAIN_NAME="devtraining.icu"

for instance in $@
do
    Instance_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
    if [ $instance != "frontend" ]; then
        Ip=$(aws ec2 describe-instances --instance-ids $Instance_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        Record_Name="$instance.$DOMAIN_NAME"
    else
        Ip=$(aws ec2 describe-instances --instance-ids $Instance_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        Record_Name="$DOMAIN_NAME" 
    fi

    echo $instance:$Private_Ip    

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
         "Comment": "creating a record set"
         ,"Changes": [{
         "Action"              : "CREATE"
         ,"ResourceRecordSet"  : {
            "Name"              : "'$Record_Name'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$Ip'"
            }]
        }
        }]
    }
    '
done
