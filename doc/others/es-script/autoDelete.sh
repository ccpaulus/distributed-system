#!/usr/bin/env bash
#删除索引脚本
#索引匹配规则： .*\-[0-9]{4}.[0-9]{2}.[0-9]{2}.*
#
#每天凌晨2点自动执行，需要赋予可执行权限，且配置到 /var/spool/cron/root
#00 02 * * * sh /opt/elasticsearch-7.1.1/bin/autoDelete.sh >/opt/logs/autoDeleteEsIndex.log 2>&1

#删除几天前的数据 实际保留的数据 deleteDays+1(当天)
deleteDays=4

if [[ ! ${PATH} =~ "/sbin" ]];then
    export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
fi


function getCurrentIp() {
    releaseInfo=`cat /etc/system-release`
	if [[ ${releaseInfo} =~ "release 7" ]];then
	    ifconfig |sed -n '2p'|awk '{printf $2}'
	else
	    ifconfig | sed -n '2p' | awk -F ':' '{print $2}' | awk '{print $1}'
	fi
}

# 过滤掉所有非数字字符串，时间需要按照yyyy mm dd 顺序出现，且日期及月份前会自动补0
# 将索引内所有非数字字符替换为空格，再以空格为分隔符，转换为数组
# 依次读取数组内容，字符长度超过1的，认为是有效的时间部分，拼接起来 拼接字符串总长度不超过8
function getDate() {
    numStr=`echo $1|sed "s/[^0-9]/ /g"`
    arr=(${numStr})
	tmp=""
    for s in ${arr[@]} ;do
        if [[ ${#s} -gt 1 && ${#tmp} -lt 8 ]];then
            tmp="${tmp}${s}"
        fi
    done
	echo ${tmp}
}

currentIp=$(getCurrentIp)

#打印当前时间
#echo `date '+%Y-%m-%d %H:%M:%S'`
#所有匹配时间格式的索引
allIndex=`curl -s http://${currentIp}:9200/_cat/indices|grep -E '(.*\-[0-9]{4}.[0-9]{2}.[0-9]{2}.*)' |cut -d ' ' -f3`

#阈值索引日期的年月日
deleteFlagDay=`date -d "-${deleteDays} day" '+%Y%m%d'`
echo "deleteDay is ${deleteFlagDay}"
for index in ${allIndex} ; do
    echo "index is ${index}"
	dateOfIndex=$(getDate ${index})
	#echo ${dateOfIndex}
	if [[ ${deleteFlagDay} -gt ${dateOfIndex} ]];then
        echo "will delete index : ${index}"
        result=$(curl -X DELETE -s http://${currentIp}:9200/${index})
        echo "delete result is : ${result}"
    fi
done
