### 1.配置文件

推荐使用 zookeeper 3.5.9

* #{ZK_HOME}/conf/java.env

zookeeper jvm配置项，具体参数请依实际情况
~~~
export JVMFLAGS="-Xms8G \
    -Xmx8G \
    -Xloggc:/opt/cloudytrace/clickhouse-zookeeper/zookeeper-3.5.9/logs/zookeeper-gc.log \
    -XX:+UseGCLogFileRotation \
    -XX:NumberOfGCLogFiles=16 \
    -XX:GCLogFileSize=16M \
    -verbose:gc \
    -XX:+PrintGCTimeStamps \
    -XX:+PrintGCDateStamps \
    -XX:+PrintGCDetails
    -XX:+PrintTenuringDistribution \
    -XX:+PrintGCApplicationStoppedTime \
    -XX:+PrintGCApplicationConcurrentTime \
    -XX:+PrintSafepointStatistics \
    -XX:+UseParNewGC \
    -XX:+UseConcMarkSweepGC \
-XX:+CMSParallelRemarkEnabled $JVMFLAGS"
~~~

* #{ZK_HOME}/conf/zoo.cfg
~~~
# 心跳时间，所有 zookeeper 的时间都以 tickTime 的倍数表示，客户端与服务器或服务器与服务器之间维持心跳，每隔1个tickTime时间就会发送一次心跳
tickTime=2000
# 初始客户端连接时间，从服务器同步到主服务器的最大心跳数，数值为 tickTime 的倍数
initLimit=10
# 主从服务器之间请求/应答的最大心跳数，数值为 tickTime 的倍数
syncLimit=5
# snapshot 数据存储的目录
dataDir=/opt/cloudytrace/zkdata
# 存储日志的目录，不配的话默认和dataDir一致
dataLogDir=/opt/cloudytrace/zklogs
# 提供 client 连接的 zookeeper 服务器端口
clientPort=2181
# 最大 client 连接数
maxClientCnxns=2000
# 保留快照数，默认3
autopurge.snapRetainCount=5
# 清理事务日志和快照文件的时间间隔,单位是小时；设置为0,表示不开启自动清理功能
autopurge.purgeInterval=1

# 以下是zk动态扩缩容的必须配置
skipACL=yes
reconfigEnabled=true
standaloneEnabled=false
dynamicConfigFile=#{ZK_HOME}/conf/zoo.cfg.dynamic
~~~

* #{ZK_HOME}/conf/zoo.cfg.dynamic，此为zookeeper动态配置文件，配置此文件才能进行动态扩缩容
~~~
server.1=#{zookeeper_node1}:2888:3888:participant;0.0.0.0:2181
server.2=#{zookeeper_node2}:2888:3888:participant;0.0.0.0:2181
.
.
.
server.N=#{zookeeper_nodeN}:2888:3888:participant;0.0.0.0:2181
~~~

* #{dataDir}/myid

在 #{dataDir} 目录下，创建myid文件，N 与 zoo.cfg.dynamic 配置中的 server.N 一致
~~~
echo N > myid
~~~


### 2.日常运维命令
~~~
 # 启动服务
 #{ZK_HOME}/bin/zkServer.sh start
 
 # 停止服务
 #{ZK_HOME}/bin/zkServer.sh stop
 
 # 服务状态查看
 #{ZK_HOME}/bin/zkServer.sh status
 
 # 连接zk client
 #{ZK_HOME}/bin/zkCli.sh server=127.0.0.1:2181
~~~


### 3.集群动态扩缩容

官方文档 http://zookeeper.apache.org/doc/r3.5.9/zookeeperReconfig.html

* 升级

<font color=red>tips：版本支持动态配置，不建议升级，不同版本间存在兼容性问题</font>

<font color=green>升级使用 rolling update方式，挨个节点进行升级；优先升级 follower，最后升级 leader</font>
~~~
1.将新版本的 zookeeper 安装包上传至服务器并安装，为保证升级正常（ dataDir 和 dataLogDir 权限），安装用户需要与原有版本完全一致

2.修改 zoo.cfg 配置文件与旧版一致（除了节点信息），新版本需添加 zoo.cfg.dynamic 文件初始化节点信息

3.将每个 follower 的老版本 zookeeper 服务停止，并启用新版本服务，最后停启 leader（保证只有一次 leader 选举）
~~~


* 动态扩容
~~~
1.将新版本的 zookeeper 安装包上传至新服务器并安装，安装用户需要与原有节点完全一致

2.修改新节点 zoo.cfg 配置文件与原节点完全一致

3.修改新节点 zoo.cfg.dynamic 文件，将原有节点配置先复制到 zoo.cfg.dynamic，然后添加新节点信息
    添加方式有两种
    （1）将每个新节点添加 zoo.cfg.dynamic 并设置为 observer 【推荐】
    （2）将新节点自身添加 zoo.cfg.dynamic 并设置为 participant
    注1：新增节点两个及以上的 participant 到 zoo.cfg.dynamic，会导致脑裂
    注2：使用（2）方法，集群扩容后，新节点配置文件会出现不一致，需要手动修改，保持一致
	
4.依次启动新节点服务，让新节点都连接到 leader

5.执行 reconfig 命令，zookeeper ensemble 动态添加和删除节点，并将配置同步到每个节点，生成 zoo.cfg.dynamic.{version} 文件，原有配置保留成为备份（文件名不变）
   # 连接 zk client 执行以下命令
   recofig 格式：
     reconfig -add #{myid1}=#{zookeeper_node1}:2888:3888:participant;2181,...#{myidN}=#{zookeeper_nodeN}:2888:3888:participant;2181
   
   例：reconfig -add 4=10.93.0.95:2888:3888:participant;2181,5=10.93.0.96:2888:3888:participant;2181,6=10.93.0.97:2888:3888:participant;2181
~~~
zoo.cfg.dynamic 样例如下，[1,2,3] 为老节点，[4,5,6] 为新增节点，此配置文件仅需在 [4,5,6] 上配置， [1,2,3] 上保持不变

执行 reconfig 命令后，集群配置会刷新并下发所有节点
~~~
server.1=10.103.95.39:2888:3888:participant;0.0.0.0:2181
server.2=10.103.95.40:2888:3888:participant;0.0.0.0:2181
server.3=10.103.95.41:2888:3888:participant;0.0.0.0:2181
server.4=10.95.64.88:2888:3888:observer;0.0.0.0:2181
server.5=10.95.64.89:2888:3888:observer;0.0.0.0:2181
server.6=10.94.78.92:2888:3888:observer;0.0.0.0:2181
~~~


* 动态缩容
~~~
# 连接zk client 执行以下命令
reconfig -remove #{myid1},#{myid2}...,#{myidN}

例：reconfig -remove 1,2

# 停止服务，在缩容的服务器上执行
#{ZK_HOME}/bin/zkServer.sh stop
~~~
