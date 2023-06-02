#!/bin/bash
homePath=/home/hadoop/shell/yarn-running-list.txt
logFile=/home/hadoop/shell/monitor_flink_job.log
basePath=/home/hadoop/shell
#将flink job保存至本地文件
cd ${basePath}
export JAVA_HOME=/data/cloudytrace/jdk
export FLINK_HOME=/data/cloudytrace/flink
export HADOOP_HOME=/data/cloudytrace/hadoop
export HADOOP_PREFIX=/data/cloudytrace/hadoop
export HADOOP_CONF=/data/cloudytrace/hadoop/etc/hadoop
export PATH=$JAVA_HOME/bin:$FLINK_HOME/bin:$HADOOP_HOME/bin:$PATH

echo $PATH >>$logFile

curl --compressed -H "Accept: application/json" -X GET "http://euphoria-cluster-master:8088/cluster/apps/RUNNING"  > yarn-running-list.txt

if [ -s /home/hadoop/shell/yarn-running-list.txt ] ; then 
  #文件不为空
  echo "`date` 文件不为空" >> ${logFile}
else
  #文件为空
  echo "`date`  yarn-running-list.txt 文件为空，跳出程序！" >> ${logFile}
  exit
fi
#新增flink job 监控任务步骤
#1、在monitorList数组中增加对应的flink job名称；注意名称不要有覆盖，例如ctmdias-etl名称会被ctmdias-etl-ctbpm覆盖
#2、在多个if判断是否存在flink job名称时，增加一个if逻辑，当job不存在时，启动该job
#. /data/cloudytrace/hadoop/bin/yarn application -list |awk  -F ' '  '{print $2}' >> /home/hadoop/shell/flink_job.log
#需要监控的flink_job名称列表。不在此范围内不监控
monitorList=("alert_sngame_prize_record" "alert_wechat_info" "ctmdias-ckwrite" "ctmdias-etl-ctuom"  "ctmdias-etl-customer" "cttde-etl-ctuom" "cttde-aggregate" "cttde-cep" "cdnp_cdnFullLog_yhprd_edgeLog" "ctmam_http_data" "ctemm_applog_exception" "ctemm_exception_event" "ctemm-exception-rsf-api" "cdnp_cdnFullLog_yhprd_origLog" "cttde-dialtest-aggregate" "alert_pay_info" )
#
for element in ${monitorList[@]}
do
#   echo "cat $homePath |awk  -F ' '  '{print $2}' | grep $element"
   catResult=`cat $homePath |awk  -F ' '  '{print $2}' | grep $element` 
   echo "`date`  $element catResult result is : $catResult " >> ${logFile}
   
  #如果cat的结果为空，表示没有查询到对应的flink job任务
  if [ -z "$catResult" ]; then 
    echo "`date` 任务： $element 查询结果为空，需要重启flink job ！" >> ${logFile}

	   if [ ${element} == 'ctmdias-etl-customer' ]; then
	     echo "`date`:start flink job, The Name is ctmdias-etl-customer"  >> ${logFile}
       nohup flink run -d -m yarn-cluster -yn 2  -ytm 2048 -ynm ctmdias-etl-customer /data/application/ctmdias/ctmdias-euphoria-etl-customer-3.1.0-SNAPSHOT-distribute.jar -env prod > ctmdias-etl-customer.log 2>&1 &
	   fi
	   
	   if [ ${element} == 'ctmdias-etl-ctuom' ]; then
	     echo "`date`:start flink job, The Name is ctmdias-etl-ctuom"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 4  -ytm 6144 -ynm ctmdias-etl-ctuom /data/application/ctmdias/ctmdias-euphoria-etl-json-3.0.0-SNAPSHOT-distribute.jar -tenant ctuom -env prod > ctmdias-etl-ctuom.log 2>&1 &
	   fi
	   
	   if [ ${element} == 'ctmdias-ckwrite' ]; then
	     echo "`date`:start flink job, The Name is ctmdias-ckwrite"  >> ${logFile}
	     nohup flink run -m yarn-cluster -yn 8 -ys 2 -ytm 4096 -p 16 -ynm ctmdias-ckwrite /data/application/ctmdias/euphoria-ckwrite-3.0.0-SNAPSHOT.jar -d -env prd -sourceNum 16 -sinkNum 16 -batchSize 50000 -batchTime 15000 &
	   fi
	   
	   if [ ${element} == 'cttde-etl-ctuom' ]; then
	     echo "`date`:start flink job, The Name is cttde-elt-ctuom"  >> ${logFile}
	     nohup /data/cloudytrace/flink/bin/flink run -d -m yarn-cluster -yn 5  -ytm 4096 -ynm cttde-etl-ctuom /data/application/ctuom/euphoria-etl-json-3.0.0-SNAPSHOT-distribute.jar -tenant ctuom -env prod  > cttde-etl-ctuom.log 2>&1 &
	   fi
	   
	   if [ ${element} == 'cttde-cep' ]; then
	     echo "`date`:start flink job, The Name is cttde-cep"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 4  -ytm 10240 -ynm cttde-cep /data/application/ctuom/euphoria-cep-3.0.0-SNAPSHOT.jar -env prod  > cttde-cep.log 2>&1 &
	   fi
	   
	   
	   if [ ${element} == 'cttde-aggregate' ]; then
	     echo "`date`:start flink job, The Name is cttde-aggregate"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 8 -ys 3  -ytm 6144 -ynm cttde-aggregate /data/application/aggregate/euphoria-aggregate-3.1.0-SNAPSHOT.jar -tenant aggregate -env prod -p 4 > cttde-aggregate.log 2>&1 &
	   fi
	   
	   if [ ${element} == 'cttde-dialtest-aggregate' ]; then
	     echo "`date`:start flink job, The Name is cttde-dialtest-aggregate"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -ys 2  -ytm 6144 -ynm cttde-dialtest-aggregate /data/application/aggregate/euphoria-aggregate-3.1.0-SNAPSHOT.jar  -env prod -tenant dialtest -p 4 > cttde-dialtest-aggregate.log 2>&1 &
	   fi
	   
	   
	   # 7*24 flink job
	   if [ ${element} == 'cdnp_cdnFullLog_yhprd_edgeLog' ]; then
	     echo "`date`:start flink job, The Name is cdnp_cdnFullLog_yhprd_edgeLog"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm cdnp_cdnFullLog_yhprd_edgeLog /data/application/7_24/euphoria-etl-splitter-3.1.0-SNAPSHOT-distribute.jar -tenant cdnp_cdnFullLog_yhprd_edgeLog_prd -file /data/application/7_24/7_24_config/cdnp_cdnFullLog_yhprd_edgeLog_prd.json  > cdnp_cdnFullLog_yhprd_edgeLog_prd.log 2>&1 &
	   fi
	   if [ ${element} == 'ctmam_http_data' ]; then
	     echo "`date`:start flink job, The Name is ctmam_http_data"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm ctmam_http_data /data/application/7_24/euphoria-etl-splitter-3.1.0-SNAPSHOT-distribute.jar -tenant ctmam_http_data_prd -file /data/application/7_24/7_24_config/ctmam_http_data_prd.json > ctmam_http_data.log 2>&1 &
	   fi
	   if [ ${element} == 'ctemm_applog_exception' ]; then
	     echo "`date`:start flink job, The Name is ctemm_applog_exception"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm ctemm_applog_exception /data/application/7_24/euphoria-etl-splitter-ctemm-3.1.0-SNAPSHOT-distribute.jar -dataSystem CTEMM -dataType applog -env prd  > ctemm_applog_exception.log 2>&1 &
	   fi
	   if [ ${element} == 'ctemm_exception_event' ]; then
	     echo "`date`:start flink job, The Name is ctemm_exception_event"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm ctemm_exception_event /data/application/7_24/euphoria-etl-splitter-ctemm-3.1.0-SNAPSHOT-distribute.jar -dataSystem CTEMM -dataType event -env prd  > ctemm_exception_event.log 2>&1 &
	   fi
	   if [ ${element} == 'ctemm-exception-rsf-api' ]; then
	     echo "`date`:start flink job, The Name is ctemm-exception-rsf-api"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm ctemm-exception-rsf-api /data/application/7_24/euphoria-etl-json-3.1.0-SNAPSHOT-distribute.jar -tenant ctemm-exception-rsf-api-prd -file /data/application/7_24/7_24_config/etl-ctemm-exception-rsf-api-prd.conf  > etl-ctemm-exception-rsf-api-prd.log 2>&1 &
	   fi
	   if [ ${element} == 'cdnp_cdnFullLog_yhprd_origLog' ]; then
	     echo "`date`:start flink job, The Name is cdnp_cdnFullLog_yhprd_origLog"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm cdnp_cdnFullLog_yhprd_origLog /data/application/7_24/euphoria-etl-splitter-3.1.0-SNAPSHOT-distribute.jar -tenant cdnp_cdnFullLog_yhprd_origLog_prd -file /data/application/7_24/7_24_config/cdnp_cdnFullLog_yhprd_origLog_prd.json  > cdnp_cdnFullLog_yhprd_origLog_prd.log 2>&1 &
	   fi
	   
	   
	   if [ ${element} == 'alert_wechat_info' ]; then
	     echo "`date`:start flink job, The Name is alert_wechat_info"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm alert_wechat_info /data/application/7_24/euphoria-etl-splitter-ctemm-3.1.0-SNAPSHOT-distribute.jar -dataSystem CTEMM -dataType wechat -env prd > alert_wechat_info.log 2>&1 &
	   fi
	   
	   if [ ${element} == 'alert_sngame_prize_record' ]; then
	     echo "`date`:start flink job, The Name is alert_sngame_prize_record"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm alert_sngame_prize_record /data/application/7_24/euphoria-etl-splitter-ctemm-3.1.0-SNAPSHOT-distribute.jar -dataSystem CTEMM -dataType sngame -env prd > alert_sngame_prize_record.log 2>&1 &
	   fi
	   
	   if [ ${element} == 'alert_pay_info' ]; then
	     echo "`date`:start flink job, The Name is alert_pay_info"  >> ${logFile}
	     nohup flink run -d -m yarn-cluster -yn 1  -ytm 4096 -ynm alert_pay_info /data/application/7_24/euphoria-etl-splitter-ctemm-3.1.0-SNAPSHOT-distribute.jar -dataSystem CTEMM -dataType pay -env prd  > alert_pay_info.log 2>&1 &
	   fi
	   
	fi
 
done
