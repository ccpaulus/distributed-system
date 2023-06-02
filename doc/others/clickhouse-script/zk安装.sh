#开启管理权限
sudo visudo

#最后这行：
snsoadmin ALL=(ALL)       NOPASSWD: ALL,!/bin/su,!/bin/bash

#修改为：
snsoadmin ALL=(ALL)       NOPASSWD: ALL

#切换为管理员
sudo su -

#如果有java则不用安装，没有需要重新安装
yum remove -y java
yum install -y java-1.8.0-openjdk
java -version

mkdir -p /data/database/clickhouse/zookeeper/
cd /data/database/clickhouse/zookeeper/ 

# 获取数据
tar xf zookeeper.tar

tar xzf zookeeper-3.4.14.tar.gz

chown -R root:root /data/database/clickhouse/zookeeper/zookeeper-3.4.14
# 复制配置文件
cp ./zoo.cfg /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/
ll /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/
chmod 0640 /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/zoo.cfg
ll /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/

cp ./java.env /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/
ll /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/
chmod 0640 /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/java.env
ll /data/database/clickhouse/zookeeper/zookeeper-3.4.14/conf/

sed -i 's/ZOO_LOG4J_PROP="INFO,CONSOLE"/ZOO_LOG4J_PROP="INFO,ROLLINGFILE"/g'  /data/database/clickhouse/zookeeper/zookeeper-3.4.14/bin/zkEnv.sh
mkdir -p /data/database/clickhouse/zookeeper/clickhouse/data

#登录不同机器，输入不同的，如
# 10.235.50.11
echo "1" > /data/database/clickhouse/zookeeper/clickhouse/data/myid
# 10.235.70.214
echo "2" > /data/database/clickhouse/zookeeper/clickhouse/data/myid
# 10.230.176.239
echo "3" > /data/database/clickhouse/zookeeper/clickhouse/data/myid
echo "4" > /data/database/clickhouse/zookeeper/clickhouse/data/myid
echo "5" > /data/database/clickhouse/zookeeper/clickhouse/data/myid

cat  /data/database/clickhouse/zookeeper/clickhouse/data/myid

cd /data/database/clickhouse/zookeeper/zookeeper-3.4.14
./bin/zkServer.sh restart
./bin/zkServer.sh status
./bin/zkServer.sh stop

ls /data/database/clickhouse/zookeeper/zookeeper-3.4.14
ps -ef | grep zookeeper