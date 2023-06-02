#!/bin/bash
logFile=/opt/hadoop/shell/hadoop_node_monitor_log.log

export JAVA_HOME=/opt/hadoop/jdk1.8.0_181
export HADOOP_HOME=/opt/hadoop/hadoop
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$PATH
echo $PATH >>$logFile

nodeType=$1

#查找运行中的进程是否包含YARN必须启动的进程
if [ ${nodeType} == "master" ];then

	nameNode=`jps|grep NameNode|grep -v grep`
	secondaryNameNode=`jps|grep SecondaryNameNode|grep -v grep`
	resourceManager=`jps|grep ResourceManager|grep -v grep`
	
	if [ ! -n  "${nameNode}" ];then
		echo "`date` nameNode does not exist"
		echo "`date` nameNode starting ..."
		nohup sh ${HADOOP_HOME}/sbin/hadoop-daemon.sh start namenode >> ${logFile} 2>&1 &
	else
		echo "`date` nameNode exists"
	fi
	
	if [ ! -n  "${secondaryNameNode}" ];then
		echo "`date` secondaryNameNode does not exist"
		echo "`date` secondaryNameNode starting ..."
		nohup sh ${HADOOP_HOME}/sbin/hadoop-daemon.sh start secondarynamenode >> ${logFile} 2>&1 &
	else
		echo "`date` secondaryNameNode exists"
	fi

	if [ ! -n "${resourceManager}" ];then
		echo "`date` resourceManager does not exist"
		echo "`date` resourceManager starting ..."
		nohup sh ${HADOOP_HOME}/sbin/yarn-daemon.sh start resourcemanager >> ${logFile} 2>&1 &
	else
		echo "`date` resourceManager exists"
	fi
	
elif [ ${nodeType} == "slave" ];then

	dataNode=`jps|grep DataNode|grep -v grep`
	nodeManager=`jps|grep NodeManager|grep -v grep`

	if [ ! -n "${dataNode}" ];then
		echo "`date` dataNode does not exist"
		echo "`date` dataNode starting ..."
		nohup sh ${HADOOP_HOME}/sbin/hadoop-daemon.sh start datanode >> ${logFile} 2>&1 &
	else
		echo "`date` dataNode exists"
	fi

	if [ ! -n "${nodeManager}" ];then
		echo "`date` nodeManager does not exist"
		echo "`date` nodeManager starting ..."
		nohup sh ${HADOOP_HOME}/sbin/yarn-daemon.sh start nodemanager >> ${logFile} 2>&1 &
	else
		echo "`date` nodeManager exists"
	fi
	
else
	echo "`date` nodeType is error"
fi


