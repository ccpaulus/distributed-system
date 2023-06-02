#!/bin/bash
#启动es脚本，放置在es/bin 目录下
#bin/restartEs.sh

cd `dirname $0`
#BIN_DIR=`pwd`
#ES_HOME=`cd ${BIN_DIR}/..;pwd`
INSTALL_HOME="/opt"

ES_HOME=`ls -d ${INSTALL_HOME}/elasticsearch* | grep -v zip`
ES_ID=`ps -ef | grep java | grep elasticsearch |grep -v 'grep'|awk '{print $2}'`

#当前登录的用户
currentUser=${USER}
#es用户
ES_USER=`ls -l ${ES_HOME}/LICENSE.txt | awk -F ' ' '{print $3}'`

#打印下当前时间
date +"%Y-%m-%d %H:%M:%S"

if [[ x"" != x"$ES_ID" ]];then
	echo "es is already running,the pid is $ES_ID";
	exit 0;
else
	echo "no es is running, will start";
fi

#root用户或者不是es用户登录
if [[ x"root" == x"$currentUser" || x"${currentUser}" != x"${ES_USER}" ]];then
su ${ES_USER} << EOF
cd ${ES_HOME}
bin/elasticsearch -d -p pid
EOF
else
    ./elasticsearch -d -p pid
fi
echo  "Waitting 15 seconds to make sure es start ok ....."
sleep 15s
ES_ID=`ps -ef | grep java | grep elasticsearch |grep -v 'grep'|awk '{print $2}'`
if [[ x"" != x"$ES_ID" ]];then
	echo "start es success,pid is $ES_ID"
	exit 0
else
	echo "start es error"
	exit 1
fi
