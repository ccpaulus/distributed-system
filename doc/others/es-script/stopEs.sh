#!/bin/bash

cd `dirname $0`
#BIN_DIR=`pwd`
#ES_HOME=`cd ${BIN_DIR}/..;pwd`

ES_ID=`ps -ef |grep elasticsearch |grep -v 'grep'|awk '{print $2}'`

HOST_NAME=`hostname`

echo "now is at $HOST_NAME"

#删除定时启动
sed -i "/startEs/d" /var/spool/cron/root

if [[ x"" != x"$ES_ID" ]];then
	echo "the es_id is $ES_ID, will kill it";
	kill -9 ${ES_ID}
	sleep 3;
	ES_ID=`ps -ef |grep elasticsearch |grep -vE 'grep|startEs.sh|stopEs.sh'|awk '{print $2}'`
	if [[ x"" != x"$ES_ID" ]];then
		echo "$HOST_NAME kill es fail"
		exit 1;
	else
		echo "killed";
	fi
else
	echo "no es is running";
