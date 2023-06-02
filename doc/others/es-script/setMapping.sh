#!/bin/bash
#设置es的mapping属性
#会根据传入的Num设置副本数
#sh setMapping.sh
# masterIp 为任意一个master节点的ip
# shardNum 为索引分片个数

# 获取当前机器的ip 无参
# 规则：取ifconfig的第二行， 以 : 分割，取第二位，再以 空格分割， 取第一位
# $(getCurrentIp)
function getCurrentIp() {
    releaseInfo=`cat /etc/system-release`
	if [[ ${releaseInfo} =~ "release 7" ]];then
	    ifconfig | sed -n '2p'| awk '{printf $2}'
	else
	    ifconfig | sed -n '2p' | awk -F ':' '{print $2}' | awk '{print $1}'
	fi
}

if [[ $# -ne 1 ]];then
    echo -e "\e[31mERROR: Usage:$0 {shardNum} \n\e[m"
    exit 1
fi

#当前节点的ip
masterIp=$(getCurrentIp)
#分片数
shardNum=$1

#安装目标目录
INSTALL_HOME="/opt"

ES_HOME=`ls -d ${INSTALL_HOME}/elasticsearch*  | grep -v .zip`
if [[ x"" == x"$ES_HOME" ]];then
    echo "error, cant not find the es!"
    exit 1
fi

#检查mapping文件
ls ${ES_HOME}/mapping/* >/dev/null 2>&1 || { echo "can not find mapping file,exit"; exit 1; }

#设置副本数，为data节点数
sed -i "s/{number.of.shards}/$shardNum/g" ${ES_HOME}/mapping/*

for mappingFile in $(ls ${ES_HOME}/mapping/*) ; do
    name=${mappingFile##*/}
    curl -s -X PUT -H 'Content-Type: application/json' ${masterIp}:9200/_template/${name}  -d@${mappingFile} > /dev/null 2>&1
done

echo "{\"returnCode\":\"0\"}"
