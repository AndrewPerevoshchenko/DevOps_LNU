#!/bin/bash
RUNDT="25.04.23"
hostname="mysqlSlave"
password="111"
port=3306
threshold=500

Last_IO_Error=`mysql -h mysqlSlave -u root -p$password -P $port -e"show slave status\G"|grep -i Last_IO_Error|awk -F ":" '{print $2}'|sed 's/ //g'`
Last_SQL_Error=`mysql -h mysqlSlave -u root -p$password -P $port -e"show slave status\G"|grep -i Last_SQL_Error|awk -F ":" '{print $2}'|sed 's/ //g'`
Last_Error=`mysql -h mysqlSlave -u root -p$password -P $port -e"show slave status\G"|grep -i Last_Error|awk -F ":" '{print $2}'|sed 's/ //g'`
Seconds_Behind_Master=`mysql -h mysqlSlave -u root -p$password -P $port -e"show slave status\G"|grep -i Seconds_Behind_Master|awk -F ":" '{print $2}'|sed 's/ //g'`

if [ -z "$Last_IO_Error" ] && [ -z "$Last_SQL_Error" ] && [ -z "$Last_Error" ]
then
    echo "fine"
else
    echo "replication not working for server $hostname for  $RUNDT" >>/output/resultFile.txt 
fi

if [ "$Seconds_Behind_Master" != "$threshold" ]
then
    echo "Replication lag is greater than 500 on server $hostname for $RUNDT" >>/output/resultFile.txt 
fi