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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo


dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbitmq"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabled rabbitmq"

systemctl start rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "Started Rabbitmq"

rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "Usercreated"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Validate permission"

END_TIME=$(date +%s)

TOTAL_TIME=$(( START_TIME-END_TIME ))

echo -e "$G  SCRIPT EXECUTED $TOTAL_TIME  $N"
