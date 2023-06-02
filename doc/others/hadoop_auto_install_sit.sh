#!/bin/bash

#此脚本不包含安装包解压等操作，需要有一个节点已安装HDFS和YARN
#此脚本不实现HDFS和YARN的HA
#此脚本仅限于HADOOP2.8.5版本，其他版本号相差较大的版本可能无法兼容
#此脚本不包含免密登录
#此脚本需要手动配置master节点的/etc/hosts
logFile=/opt/hadoop/shell/hadoop_node_monitor_log.log

#【1】配置/etc/hosts
current_hosts=("ctmdiassitapp130")
additional_hosts=("ctmdiassitapp131" "ctmdiassitapp132")


#10.237.0.97 ctmdiassitapp130
#10.237.0.48 ctmdiassitapp131
#10.237.0.63 ctmdiassitapp132
#10.237.0.102 ctmdiassitapp133
#10.237.0.59 ctmdiassitapp134
#10.237.0.56 ctmdiassitapp135
#10.237.0.46 ctmdiassitapp136
#10.237.3.112 ctmdiassitapp144


10.237.0.97 ctmdiassitapp130
10.237.0.48 ctmdiassitapp131
10.237.0.63 ctmdiassitapp132

#需要配置的环境变量
JAVA_HOME=/opt/hadoop/jdk1.8.0_181
HADOOP_HOME=/opt/hadoop/hadoop
PATH=$HADOOP_HOME/bin:$JAVA_HOME/bin:$PATH
YARN_PID_DIR=/opt/hadoop/pid
HADOOP_PID_DIR=/opt/hadoop/pid


for variable in `cat env`
do
	echo $variable
	ssh root@ctmdiassitapp130 "echo -e $variable >> >> /etc/bashrc"
done


additionalHostsHandler(){
	IFS_old=$IFS
	IFS=$'\n'
	for host in `cat additional_hosts`
	do
		IFS=$IFS_old
		$array=($host)
		hostName=$array[1]
		#【1】复制master节点的软件文件到安装节点相同目录
		ssh root@$hostName "mkdir -p $HADOOP_HOME"
		scp -r $HADOOP_HOME root@$hostName:$HADOOP_HOME
	done
	IFS=$IFS_old
}

$variable=`cat env`
ssh root@ctmdiassitapp133 "echo -e $variable >> /opt/hadoop_auto_install/test"

for element in ${additional_hosts[@]}
do
	#【2】配置环境变量
	JAVA_HOME=/opt/hadoop/jdk1.8.0_181
	HADOOP_HOME=/opt/hadoop/hadoop
	PATH=$HADOOP_HOME/bin:$JAVA_HOME/bin:$PATH
	YARN_PID_DIR=/opt/hadoop/pid
	HADOOP_PID_DIR=/opt/hadoop/pid
done

echo -e "10.237.0.46 ctmdiassitapp136\n10.237.0.48 ctmdiassitapp131" >> /etc/hosts

src=""
dst=""

ssh root@ctmdiassitapp133 "mkdir -p /opt/c"
scp -r /data/install/somefolder root@ftpserver.com:/data/install/somefolder


echo -e "" >> /etc/bashrc

nodeType=$1

#查找运行中的进程是否包含YARN必须启动的进程
if [ ${nodeType} == "master" ];then

	nameNode=`jps|grep NameNode|grep -v grep`
	secondaryNameNode= `jps|grep SecondaryNameNode|grep -v grep`
	resourceManager=`jps|grep ResourceManager|grep -v grep`
	
	if [ ! -n  "${nameNode}" ];then
		echo "`date` nameNode does not exist"
		echo "`date` nameNode starting ..."
		nohup sh ${HADOOP_HOME}/sbin/hadoop-daemon.sh start namenode >> $logFile 2>&1 &
	else
		echo "`date` nameNode exists"
	fi
	
	if [ ! -n  "${secondaryNameNode}" ];then
		echo "`date` secondaryNameNode does not exist"
		echo "`date` secondaryNameNode starting ..."
		nohup sh ${HADOOP_HOME}/sbin/hadoop-daemon.sh start secondarynamenode >> $logFile 2>&1 &
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
