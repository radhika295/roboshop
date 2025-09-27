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
    echo -e "User already exist....$Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Created App folder"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip   &>>$LOG_FILE
VALIDATE $? "Downloaded Catalgoue from S3"

cd /app
VALIDATE $? "chagned into app directory"

rm -rf /app/*
VALIDATE $? "Remove old files"

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unziped the catalgoue folder"

npm install &>>$LOG_FILE
VALIDATE $? "nodejs installed successfully"

cp $SCRIPT_DIR/cart.service  /etc/systemd/system/cart.service
VALIDATE $? "catalgoue service is implemented"

systemctl daemon-reload
VALIDATE $? "Restarted cart"

systemctl enable cart 
VALIDATE $? "Restarted cart"

systemctl start cart
VALIDATE $? "Restarted cart"

