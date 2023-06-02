#!/usr/bin/env bash
# es自动安装脚本
#脚本参数说明
#-n | --clusterName 集群名称，同一个集群，名称要一致
#-m | --mode 当前节点类型，共 master、data、all(既是master也是data)
#-l | --list master节点ip列表，以 , 分割
#-u | --user 待创建的es用户名，如果非root用户登陆，取当前用户，否则默认为snsoadmin
#-p | --path es安装目录，默认/opt
#-o | --logPath es日志目录，默认/data/es/logs
#-d | --dataPth es数据目录，默认/data/es/data
#下载的es包为修改版，包含mapping文件，已有默认配置，必备的动态配置采用占位标志 方便替换
#默认配置如下：
#http.port: 9200
#transport.tcp.port: 9300
#path.data: /data/es/data
#path.logs: /data/es/log
#bootstrap.memory_lock: true
#bootstrap.system_call_filter: false
#discovery.zen.minimum_master_nodes: masterNum / 2
#jvm内存为机器内存的一半

# 获取当前机器的ip
# $(getCurrentIp)
function getCurrentIp() {
    releaseInfo=$(cat /etc/system-release)
	if [[ ${releaseInfo} =~ "release 7" ]];then
	    ifconfig | sed -n '2p'| awk '{printf $2}'
	else
	    ifconfig | sed -n '2p' | awk -F ':' '{print $2}' | awk '{print $1}'
	fi
}

#脚本所在目录
DIRNAME=$(dirname "$0")
CURRENT_DIR=$(cd "${DIRNAME}" || exit 1;pwd)

#安装所需的参数
#安装目标目录
INSTALL_HOME="/opt"
#es自身日志目录 有数据盘建议防在数据盘
#LOG_HOME="/opt/logs/es"
LOG_HOME="/data/es/logs"
#数据目录
DATA_HOME="/data/es/data"
#系统配置文件
LIMITS_CONF=/etc/security/limits.conf
SYSCTL_CONF=/etc/sysctl.conf
#es的用户
ES_USER="snsoadmin"
#ES_GROUP="snsoadmin"
clusterName="ares-es"
nodeMode=""
masterList=""

currentIp=$(getCurrentIp)
#当前执行脚本的用户
currentUser=${USER}
master=false
data=false
# 如果/data目录不存在，则修改默认目录
if [[ ! -d /data ]];then
    LOG_HOME="${INSTALL_HOME}/logs/es"
    DATA_HOME="${INSTALL_HOME}/data/es"
fi

show_usage="args: [-n , -m , -l , -u, -p, -o, -d]\
                                  [--clusterName=, --mode=, --list=, --user=, --installPath, --logPth, --dataPth]"

GETOPT_ARGS=$(getopt -o n:m:l:u:p:o:d: -al clusterName:,mode:,list:,user:,installPath:,logPth:,dataPth: -- "$@")
eval set -- "$GETOPT_ARGS"

#获取参数
while [ -n "$1" ]
do
        case "$1" in
                -n|--clusterName) clusterName=$2; shift 2;;
                -m|--mode) nodeMode=$2; shift 2;;
                -l|--list) masterList=$2; shift 2;;
                -u|--user) ES_USER=$2; shift 2;;
				-p|--installPath) INSTALL_HOME=$2; shift 2;;
				-o|--logPth) LOG_HOME=$2; shift 2;;
				-d|--dataPth) DATA_HOME=$2; shift 2;;
                --) break ;;
                *) echo $1,$2,$show_usage; break ;;
        esac
done
if [[ x"" == x"$nodeMode" || x"" == x"$masterList" ]];then
    echo "error param, must set mode and list";
	echo $show_usage
	exit 1
fi

#如果当前登录的是root用户，es7不可以以root启动，需要创建新的用户
if [[ x"root" == x"$currentUser" ]];then
    #创建es的用户组和用户
#    grep -E "^${ES_GROUP}" /etc/group >& /dev/null
#    if [[ $? -ne 0 ]];then
#        groupadd ${ES_GROUP}
#    fi
    grep -E "^${ES_USER}" /etc/passwd >& /dev/null
    if [[ $? -ne 0 ]];then
#        useradd -m -g ${ES_GROUP} ${ES_USER}
        useradd -m ${ES_USER}
    fi
    #增加至wheel组，可以通过su 切换至用户
    #usermod -G wheel ${ES_USER}
else
   ES_USER=${currentUser}
fi

echo "$clusterName $nodeMode $masterList $ES_USER $INSTALL_HOME $LOG_HOME $DATA_HOME"

#判断当前节点类型
if [[ x"master" == x"$nodeMode" ]];then
    master=true
    echo "current node is master"
elif [[ x"data" == x"$nodeMode" ]];then
    data=true
    echo "current node is data"
elif [[ x"all" == x"$nodeMode" ]];then
    master=true
    data=true
	nodeMode="master"
    echo "current node is master and data"
else
    echo "error nodeMode"
    exit 1
fi

#将,分割的ip列表转为数组
ipArr=(${masterList//,/ })
#当前节点名称
nodeName="${currentIp}-${nodeMode}"
echo "current node $nodeName"

#拼接自发现master列表
seedHosts=""
masterNodes=""
for (( index = 0; index < ${#ipArr[*]}; index++ )); do
    seedHosts=${seedHosts}"\"${ipArr[index]}\", "
	masterNodes=${masterNodes}"\"${ipArr[index]}-master\", "
done
#从右边开始，删除第一个 , 及其右边的字符
seedHosts=${seedHosts%,*}
masterNodes=${masterNodes%,*}
echo "seedHosts is $seedHosts"

#当前系统总内存 GB
totalMemory=`free -g | awk '/Mem/ {print $2}'`
#es的 jvm 占用一半
jvmMemory=$[(totalMemory+1)/2]
echo "jvmMemory is $jvmMemory"

#在当前目录查找ES安装包
ES_ZIP=`ls ${CURRENT_DIR}/elasticsearch*.zip`
if [[ x"" != x"$ES_ZIP" ]];then
    echo "find es zip,will unzip..."
else
    echo "can not find es-zip"
fi

#删除已经存在的elasticsearch文件夹
ES_HOME=$(find "${INSTALL_HOME}" -maxdepth 1 -type d -name "elasticsearch*"  | grep -v zip)
if [[ x"" != x"$ES_HOME" ]];then
    echo "at ${INSTALL_HOME} find ${ES_HOME} existed, will delete"
    rm -rf ${ES_HOME}
fi
unzip -o ${ES_ZIP} -d ${INSTALL_HOME} >/dev/null 2>&1
ES_HOME=$(find "${INSTALL_HOME}" -maxdepth 1 -type d -name "elasticsearch*"  | grep -v zip)
if [[ x"" == x"$ES_HOME" ]];then
    echo "error, unzip es file!"
    exit 1
fi

echo "esHome is ${ES_HOME}"

#修改jvm内存配置
sed -i "s/{jvm.memory}/$jvmMemory/g" ${ES_HOME}/config/jvm.options

#修改elasticsearch.yml配置
#将目录中的 /  替换成 \/
dataPth=${DATA_HOME//\//\\\/}
logPth=${LOG_HOME//\//\\\/}
sed -i "s/{cluster.name}/$clusterName/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{data.path}/$dataPth/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{logs.path}/$logPth/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{node.name}/$nodeName/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{node.master}/$master/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{node.data}/$data/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{network.host}/$currentIp/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{seed.hosts}/$seedHosts/g" ${ES_HOME}/config/elasticsearch.yml
sed -i "s/{master.nodes}/$masterNodes/g" ${ES_HOME}/config/elasticsearch.yml

#data目录下创建es文件夹。保存data和log
if [[ -d ${LOG_HOME} ]];then
    rm -rf ${LOG_HOME}
fi
mkdir -p ${LOG_HOME}

if [[ -d ${DATA_HOME} ]];then
    rm -rf ${DATA_HOME}
fi
mkdir -p ${DATA_HOME}

#修改文件权限
chown -R ${ES_USER}:${ES_USER} ${ES_HOME}
chown -R ${ES_USER}:${ES_USER} ${DATA_HOME}
chown -R ${ES_USER}:${ES_USER} ${LOG_HOME}
chmod -R 755 ${ES_HOME}

#修改系统相关配置
swapoff -a

sed -i "/${ES_USER}.*/d" ${LIMITS_CONF}

sed -i '$a\'"$ES_USER"' soft nofile 655360' ${LIMITS_CONF}
sed -i '$a\'"$ES_USER"' hard nofile 655360' ${LIMITS_CONF}
sed -i '$a\'"$ES_USER"' soft memlock unlimited' ${LIMITS_CONF}
sed -i '$a\'"$ES_USER"' hard memlock unlimited' ${LIMITS_CONF}
sed -i '$a\'"$ES_USER"' soft  nproc  655360' ${LIMITS_CONF}
sed -i '$a\'"$ES_USER"' hard  nproc  655360' ${LIMITS_CONF}

#部分系统在/etc/security/limits.d对非root用户存在限制，需要修改
files=$(ls /etc/security/limits.d/*-nproc.conf 2> /dev/null | wc -l)
if [[ ${files} -gt 0 ]];then
    sed -i 's/*.*soft.*nproc.*/* soft nproc 655360/' /etc/security/limits.d/*-nproc.conf
fi

sed -i "/vm.max_map_count=.*/d" ${SYSCTL_CONF}
sed -i "/vm.swappiness=.*/d" ${SYSCTL_CONF}

sed -i '$a\vm.max_map_count=655360' ${SYSCTL_CONF}
sed -i '$a\vm.swappiness=0' ${SYSCTL_CONF}
sysctl -p >/dev/null 2>&1

#将启动脚本配置到定时任务中
#部分机器存在没有定时任务文件的情况
sed -i "/startEs/d" /var/spool/cron/root
echo "*/5 * * * * sh ${ES_HOME}/bin/startEs.sh >/dev/null 2>&1" >> /var/spool/cron/root
#sed -i '$a\*/5 * * * * sh '"${ES_HOME}"'/bin/startEs.sh >/dev/null 2>&1' /var/spool/cron/root

#在master节点配置删除数据的定时任务
if [[ "true" == "${master}" ]];then
    sed -i "/elasticsearch.*autoDelete/d" /var/spool/cron/root
    echo "*00 02 * * * sh ${ES_HOME}/bin/autoDelete.sh >/dev/null 2>&1" >> /var/spool/cron/root
fi


/sbin/service crond reload

echo "{\"returnCode\":\"0\"}"
exit 0