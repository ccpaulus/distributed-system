### 1.修改配置文件
<font color=red>tips1：已下为新建集群时的配置操作，如果在已有集群上进行横向扩容，新节点需与现有节点保持完全一致，将现有节点的安装目录打包 copy 至 新节点即可</font>

<font color=green>tips2：确保所有节点配置完全一致</font>

* #{HADOOP_HOME}/etc/hadoop/slaves

修改slaves文件，加入集群从节点 ( hostname | IP )，例：
~~~
10.93.1.92
10.93.1.93
10.93.1.94
10.93.1.95
10.93.1.96
10.93.1.97
~~~

* #{HADOOP_HOME}/etc/hadoop/core-site.xml
~~~
<configuration>

    <!-- 默认文件系统名 -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://#{nsname}</value>
    </property>
    
    <!-- 临时目录，与之前步骤创建保持一致 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>file:/data/hadoop/tmp</value>
    </property>
    
    <!-- zookeeper服务器，ZKFailoverController 自动故障转移使用 -->
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>#{zookeeper_node1:port1},#{zookeeper_node2:port2}...,#{zookeeper_nodeN:portN}</value>
    </property>
    
</configuration>
~~~

core-site.xml 全量参数

https://hadoop.apache.org/docs/r2.8.5/hadoop-project-dist/hadoop-common/core-default.xml


* #{HADOOP_HOME}/etc/hadoop/hdfs-site.xml
~~~
<configuration>

    <!-- dfs.nameservices名称，要和 core-site.xml 的 dfs.defaultFS 的值一致， 如果要与其他集群使用同一zookeeper集群，注意名称不能重复 -->
    <property>
        <name>dfs.nameservices</name>
        <value>#{nsname}</value>
    </property>
    <!-- 同一个nameservice下的多个namenode名称 -->
    <property>
        <name>dfs.ha.namenodes.#{nsname}</name>
        <value>nn1,nn2</value>
    </property>
    
    <property>
        <name>dfs.namenode.rpc-address.#{nsname}.nn1</name>
        <value>#{nn1_host}:9000</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.#{nsname}.nn1</name>
        <value>#{nn1_host}:50070</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.#{nsname}.nn2</name>
        <value>#{nn2_host}:9000</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.#{nsname}.nn2</name>
        <value>#{nn2_host}:50070</value>
    </property>
    
    <!-- A directory on shared storage between the multiple namenodes in an HA cluster. 
    This directory will be written by the active and read by the standby in order to keep the namespaces synchronized. 
    This directory does not need to be listed in dfs.namenode.edits.dir above. 
    It should be left empty in a non-HA cluster. -->
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://#{journal1_host}:8485;#{journal2_host}:8485;#{journal3_host}:8485/#{nsname}</value>
    </property>
    
    <!-- journalnode数据目录，与之前步骤创建保持一致 -->
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>/data/hadoop/journaldata</value>
    </property>
    
    <!-- hdfs高可用自动失败转移 -->
    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>
    
    <!-- 客户端连接可用状态的namenode所用的代理类 -->
    <property>
        <name>dfs.client.failover.proxy.provider.#{nsname}</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>
    
    <!-- namenode切换时，使用ssh方式进行操作 -->
    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>sshfence</value>
    </property>
    <!-- 如果使用ssh进行故障切换，使用ssh通信时用的密钥存储的位置 -->
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/home/#{username}/.ssh/id_rsa</value>
    </property>
    <!-- SSH连接超时时间 -->
    <property>
        <name>dfs.ha.fencing.ssh.connect-timeout</name>
        <value>30000</value>
    </property>
    
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    
    <!-- Determines where on the local filesystem the DFS name node should store the name table(fsimage). 
    If this is a comma-delimited list of directories then the name table is replicated in all of the directories, for redundancy -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:/data/hadoop/hdfs/name</value>
    </property>
    
    <!-- Determines where on the local filesystem an DFS data node should store its blocks. 
    If this is a comma-delimited list of directories, then data will be stored in all named directories, typically on different devices. 
    The directories should be tagged with corresponding storage types ([SSD]/[DISK]/[ARCHIVE]/[RAM_DISK]) for HDFS storage policies. 
    The default storage type will be DISK if the directory does not have a storage type tagged explicitly. 
    Directories that do not exist will be created if local filesystem permission allows. -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:/data/hadoop/hdfs/data</value>
    </property>
    
    <!-- 不允许连接到namenode的主机列表，格式同 slaves 文件（hostname|IP），节点动态变更时使用，该文件需手动创建，名字、路径自定义，初始时内容为空 -->
    <property>
        <name>dfs.hosts.exclude</name>
        <value>#{HADOOP_HOME}/etc/hadoop/dfs.hosts.exclude</value>
    </property>
    
</configuration>
~~~

hdfs-site.xml 全量参数

https://hadoop.apache.org/docs/r2.8.5/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml


### 2.初始化&启动
* 启动 zookeeper，在 zookeeper 安装节点上执行
~~~
zkServer.sh start
~~~

* hadoop 初始化启动，在 namenode 上执行
~~~
# 1.在 hdfs-site.xml 中配置的 journalnode 上启动journalnode服务
hadoop-daemon.sh start journalnode

# 2.格式化 namenode（active节点执行）
hdfs namenode -format

# 3.配置并同步 namenode , a、b方案 取一即可
  a) #启动第一个 namenode（active节点执行）
     hadoop-daemon.sh start namenode

     # 同步namenode文件（standby节点执行）
     hdfs namenode -bootstrapStandby
     
     # 启动第二个namenode（standby节点执行）
     hadoop-daemon.sh start namenode
     
  b) #使用 scp 直接复制 data目录 亦可（scp可以配置完后执行start-dfs.sh启动所有节点）
     scp -r dfs #{username}@#{namenode_standby}:/data/hadoop/hdfs/data/

# 4.格式化ZKFC
hdfs zkfc -formatZK

# 5.启动dfs集群【以上已经启动的服务，会给出警告，但不会重复启动，请放心食用】
start-dfs.sh
~~~


### 3.日常运维命令
~~~
# 关闭集群
#{HADOOP_HOME}/sbin/stop-dfs.sh

# 单独启动|关闭 journalnode 服务
#{HADOOP_HOME}/sbin/hadoop-daemon.sh start|stop journalnode

# 单独启动|关闭 zkfc 服务
#{HADOOP_HOME}/sbin/hadoop-daemon.sh start|stop zkfc

# 单独启动|关闭 namenode 服务，在 namenode 节点上执行
#{HADOOP_HOME}/sbin/hadoop-daemon.sh start|stop namenode

# 单独启动|关闭 datanode 服务，在 datanode 节点上执行
#{HADOOP_HOME}/sbin/hadoop-daemon.sh start|stop datanode

# HDFS HA 服务查看
hdfs haadmin -getAllServiceState

# 其余 hdfs 命令，查看帮助文档
hdfs -h
~~~
