#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR :: Please run this scirpt with root privilage $N"
    exit 1
fi

START_TIME=$(date +%s)

SCRIPT_DIR=$PWD

LOGS_FOLDER="/var/log/shell-roboshop"

mkdir -p $LOGS_FOLDER

SCRIPT_NAME=$( echo $0 | cut -d "." -f1)

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

#mkdir -p $LOGS_FOLDER

echo "Script satrted executed at: $(date)" | tee -a $LOG_FILE

VALIDATE() {
    if [ $1 -eq 0 ]; then
         echo -e "$2  : $G Success $N" | tee -a $LOG_FILE
         
    else    
         echo -e "$2  : $R Failed $N" | tee -a $LOG_FILE
         exit 1
    fi
}


dnf install maven -y

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "System user is created"
else
    echo -e "User already exist....$Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Created App folder"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip    &>>$LOG_FILE
VALIDATE $? "Downloaded shipping from S3"

cd /app
VALIDATE $? "chagned into app directory"

rm -rf /app/*
VALIDATE $? "Remove old files"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unziped the shipping folder"

cd /app 
mvn clean package 
mv target/shipping-1.0.jar shipping.jar 


cp $SCRIPT_DIR/shipping.service  /etc/systemd/system/shipping.service
VALIDATE $? "shipping service is implemented"

systemctl daemon-reload
VALIDATE $? "Restarted cart"

systemctl enable shipping 
VALIDATE $? "Restarted shipping"

systemctl start shipping
VALIDATE $? "Restarted shipping"