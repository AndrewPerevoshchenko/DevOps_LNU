#!/bin/bash




docker-compose down -v

rm -rf ./master/data/*

rm -rf ./slave/data/*

docker-compose build

docker-compose up -d




until docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'

do

    echo "Waiting for mysql_master database connection..."

    sleep 4

done




priv_stmt='CREATE USER "mydb_slave_user_Andrew"@"%" IDENTIFIED BY "mydb_slave_pwd_Andrew"; GRANT REPLICATION SLAVE ON *.* TO "mydb_slave_user_Andrew"@"%"; FLUSH PRIVILEGES;'

docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$priv_stmt'"




until docker-compose exec mysqlSlave sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'

do

    echo "Waiting for mysqlSlave database connection..."

    sleep 4

done




MS_STATUS=`docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e "SHOW MASTER STATUS"'`

CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`

CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`




start_slave_stmt="CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='mydb_slave_user_Andrew',MASTER_PASSWORD='mydb_slave_pwd_Andrew',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"

start_slave_cmd='export MYSQL_PWD=111; mysql -u root -e "'

start_slave_cmd+="$start_slave_stmt"

start_slave_cmd+='"'

docker exec mysqlSlave sh -c "$start_slave_cmd"




docker exec mysqlSlave sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"