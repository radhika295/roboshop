#!/bin/bash
set -e pipefail

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

MONGODB_HOST=mongodb.devtraining.icu

echo "Script satrted executed at: $(date)" | tee -a $LOG_FILE


dnf module disable nodejs -y &>>$LOG_FILE


dnf module enable nodejs:20 -y &>>$LOG_FILE

 
dnf install nodejs -y &>>$LOG_FILE


id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    
else
    echo -e "User already exist....$Y Skipping $N"
fi

mkdir -p /app 


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE


cd /app


rm -rf /app/*


unzip /tmp/catalogue.zip &>>$LOG_FILE


npm install &>>$LOG_FILE


cp $SCRIPT_DIR/catalogue.service  /etc/systemd/system/catalogue.service


systemctl daemon-reload &>>$LOG_FILE


systemctl enable catalogue  &>>$LOG_FILE


systemctl start catalogue &>>$LOG_FILE


cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo &>>$LOG_FILE

dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi


systemctl restart catalogue
VALIDATE $? "Restarted catalogue"

#mongosh --host mongodb.devtraining.icu </app/db/master-data.js &>>$LOG_FILE
