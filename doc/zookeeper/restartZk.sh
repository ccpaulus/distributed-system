#!/bin/sh
# zk重启脚本
#安装目录
INSTALL_HOME="/opt"

ZK_HOME=`ls -d ${INSTALL_HOME}/zookeeper*`
if [[ x"" == x"ZK_HOME" || ! -d ${ZK_HOME} ]];then
    echo "error, no zk!"
    exit 1
fi

HOST_NAME=`hostname`

PID=`ps -ef |grep zookeeper |grep -v 'grep'|awk '{print $2}'`

if [[ x"" != x"$PID" ]];then
	echo "pid is $PID, will kill it";
	kill -9 ${PID}
	sleep 3s;
	PID=`ps -ef |grep zookeeper |grep -v 'grep'|awk '{print $2}'`
	if [[ x"" != x"$ES_ID" ]];then
		echo "$HOST_NAME kill failed"
		exit 1;
	else
		echo "killed";
	fi
else
	echo "no es is running, will start";
fi

echo "now start..."
sh ${ZK_HOME}/bin/zkServer.sh start

echo  "Waitting 5 seconds to make sure zk start ok ....."
sleep 5s

PID=`ps -ef |grep zookeeper |grep -v 'grep'|awk '{print $2}'`
if [[ x"" != x"$PID" ]];then
	echo "$HOST_NAME start zk success,pid is $PID"
	exit 0
else
	echo "$HOST_NAME start zk failed"
	exit 1
