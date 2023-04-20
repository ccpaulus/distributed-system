### 1.修改配置文件
<font color=red>tips1：已下为新建集群时的配置操作，如果在已有集群上进行横向扩容，新节点需与现有节点保持完全一致，将现有节点的安装目录打包 copy 至 新节点即可</font>

<font color=green>tips2：确保所有节点配置完全一致</font>

* #{HADOOP_HOME}/etc/hadoop/slaves

hdfs配置时，已配置，无需重复配置

* #{HADOOP_HOME}/etc/hadoop/yarn-site.xml
~~~
<configuration>

    <property>
        <name>yarn.acl.enable</name>
        <value>0</value>
    </property>
    
    <!-- 开启RM高可用 -->
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>
    <!-- 指定RM的cluster id，如果要与其他集群使用同一zookeeper集群，注意名称不能重复 -->
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>#{rcname}</value>
    </property>
    <!-- 指定RM的名字 -->
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
    </property>
    <!-- 分别指定RM的地址 -->
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>#{rm1_host}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>#{rm2_host}</value>
    </property>
    <!-- 指定zk集群地址 -->
    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>#{zookeeper_node1:port1},#{zookeeper_node2:port2}...,#{zookeeper_nodeN:portN}</value>
    </property>
    <!-- 启用自动恢复 -->
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name>
        <value>true</value>
    </property>
    <!-- 指定resourcemanager的状态信息存储在zookeeper集群 -->
    <property>
        <name>yarn.resourcemanager.store.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
    </property>
    
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    
    <!-- nodemanager启动新容器所需的健康磁盘数量的最小比例，默认0.25 -->
    <property>
        <name>yarn.nodemanager.disk-health-checker.min-healthy-disks</name>
        <value>0.2</value>
    </property>
    <!-- yarn.nodemanager.local-dirs 配置项下的路径或者 yarn.nodemanager.log-dirs 配置项下的路径的磁盘使用率达到了此项值时，nodemanager 将被标志为 unhealthy，默认90.0 -->
    <property>
        <name>yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage</name>
        <value>100.0</value>
    </property>
    <!-- 单纯更改 yarn.nodemanager.disk-health-checker.min-healthy-disks 
    和 yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage极端情况下，无法解决问题；
    资源充足情况下，建议 YARN 的日志目录或中间结果目录，与 HDFS 的数据存储目录 放到不同磁盘-->
    
    <!-- 全局的application master 在yarn重试次数的限制 -->
    <property>
        <name>yarn.resourcemanager.am.max-attempts</name>
        <value>1000</value>
    </property>
    <!-- 单个任务可申请的最小物理内存量 -->
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>1024</value>
    </property>
    <!-- 单个任务可申请的最大物理内存量 -->
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>20480</value>
    </property>
    <!-- 单个任务可申请的最小CPU数 -->
    <property>
        <name>yarn.scheduler.minimum-allocation-vcores</name>
        <value>1</value>
    </property>
    <!-- 单个任务可申请的最大CPU数 -->
    <property>
        <name>yarn.scheduler.maximum-allocation-vcores</name>
        <value>9999999</value>
    </property>
    <!-- 该节点上YARN可使用的cpu个数，需根据服务器资源制定 -->
    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>60</value>
    </property>
    <!--该节点上YARN可使用的物理内存总量，需根据服务器资源制定 -->
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>204800</value>
    </property>
    <!-- 任务每使用1MB物理内存，最多可使用虚拟内存量，默认是2.1 -->
    <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>3</value>
    </property>
    
    <!-- YARN排除节点列表，格式同 slaves 文件（hostname|IP），节点动态变更时使用，该文件需手动创建，名字、路径自定义，初始时内容为空 -->
    <property>
        <name>yarn.resourcemanager.nodes.exclude-path</name>
        <value>#{HADOOP_HOME}/etc/hadoop/yarn.hosts.exclude</value>
    </property>
    
</configuration>
~~~

yarn-site.xml 全量参数

https://hadoop.apache.org/docs/r2.8.5/hadoop-yarn/hadoop-yarn-common/yarn-default.xml


### 2.初始化&启动
* yarn 初始化启动，在 resourcemanager 上执行
~~~
# 启动集群
start-yarn.sh
~~~


### 3.日常运维命令
~~~
# 关闭集群
#{HADOOP_HOME}/sbin/stop-yarn.sh

# 单独启动|关闭 resourcemanager 服务
#{HADOOP_HOME}/sbin/yarn-daemon.sh start|stop resourcemanager

# 单独启动|关闭 nodemanager 服务
#{HADOOP_HOME}/sbin/yarn-daemon.sh start|stop nodemanager

# YARN HA 服务查看
yarn rmadmin -getAllServiceState

# YARN 节点查看
yarn node -list

# YARN application 查看
yarn application -list

# YARN application kill
yarn application -kill #{applicationId}

# 其余 hdfs 命令，查看帮助文档
yarn -h
~~~
