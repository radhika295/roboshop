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
LOGS_FOLDER="/var/log/shell-roboshop"

mkdir -p $LOGS_FOLDER

SCRIPT_NAME=$( echo $0 | cut -d "." -f1)

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

#mkdir -p $LOGS_FOLDER

echo "Script satrted executed at: $(date)" | tee -a $LOG_FILE

VALIDATE() {
    if [ $1 -eq 0 ]; then
         echo -e "$2 .. : $G Success $N" | tee -a $LOG_FILE
         
    else    
         echo -e "$2 .. : $R Failed $N" | tee -a $LOG_FILE
         exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo

VALIDATE $? "Adding Repo in mongobd server"

dnf install mongodb-org -y &>>$LOG_FILE

VALIDATE $? "Mongodb Installed"

systemctl enable mongod &>>$LOG_FILE

VALIDATE $? "Enable MongoDB"

systemctl start mongod &>>$LOG_FILE

VALIDATE $? "start MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to mongodb"

systemctl restart mongodb
VALIDATE $? "Restarted Mongodb"


