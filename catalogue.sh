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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling all Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enableling Nodejs 20"
 
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installed NodeJS"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "System user is created"
else
    echo "User already exist....$Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Created App folder"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloaded Catalgoue from S3"

cd /app
VALIDATE $? "chagned into app directory"

rm -rf /app/*
VALIDATE $? "Remove old files"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unziped the catalgoue folder"

npm install &>>$LOG_FILE
VALIDATE $? "nodejs installed successfully"

cp $SCRIPT_DIR/catalogue.service  /etc/systemd/system/catalogue.service
VALIDATE $? "catalgoue service is implemented"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "system reloaded"

systemctl enable catalogue  &>>$LOG_FILE
VALIDATE $? "catalgoue service enabled"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "catalgour service started"

cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo &>>$LOG_FILE

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "mongodb installed"

mongosh --host mongodb.devtraining.icu </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "connected to mongodb and trasfer data from catalgoue to mongodb"