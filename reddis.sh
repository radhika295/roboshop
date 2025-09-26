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

END_TIME=$(date +%s)

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

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disablled the redis" 

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enableled redis"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installed Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf -e '/proctected-mode/ c protected-mode no' &>>$LOG_FILE
VALIDATE $? "changed to 0.0.0.0 and preocted mode is off"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enable redis"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Starting  redis"

END_TIME=$(date +%s)

TOTAL_TIME=(( $START_TIME-$END_TIME ))

echo -e "$G  SCRIPT EXECUTED $TOTAL_TIME  $N"