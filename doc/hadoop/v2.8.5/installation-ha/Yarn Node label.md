# Yarn Node label

### 创建HDFS目录，用于存放Node Label

~~~
hdfs dfs -mkdir -p /yarn/node-labels
~~~

### 配置yarn-site.xml配置文件

~~~
<property>
    <name>yarn.node-labels.enabled</name>
    <value>true</value>
</property>
<property>
    <name>yarn.node-labels.fs-store.root-dir</name>
    <value>hdfs://node-master:9000/yarn/node-labels</value></property>
<property>
    <name>yarn.node-labels.manager-class</name>
    <value>org.apache.hadoop.yarn.server.resourcemanager.nodelabels.RMNodeLabelsManager</value>
</property>
~~~

注：重启ResourceManager

### 创建标签列表

~~~
 yarn rmadmin -addToClusterNodeLabels label1,label2
~~~

### 给各个节点打上标签

~~~
yarn rmadmin -replaceLabelsOnNode node-master,label1
yarn rmadmin -replaceLabelsOnNode node6,label1
yarn rmadmin -replaceLabelsOnNode node7,label1
yarn rmadmin -replaceLabelsOnNode node8,label1
yarn rmadmin -replaceLabelsOnNode node9,label1
yarn rmadmin -replaceLabelsOnNode node15,label2
yarn rmadmin -replaceLabelsOnNode node16,label2
yarn rmadmin -replaceLabelsOnNode node17,label2
yarn rmadmin -replaceLabelsOnNode node18,label2
yarn rmadmin -replaceLabelsOnNode node19,label2
~~~

### 添加队列与标签的匹配关系

只修改resourcemanager节点下的${HADOOP_HOME}/etc/hadoop/capacity-scheduler.xml

~~~
<?xml version="1.0" encoding="utf-8"?>

<configuration>
    <property>
        <name>yarn.scheduler.capacity.root.queues</name>
        <value>queue1,queue2</value>
    </property>
    <!-- 配置各队列可使用的集群总资源占比 -->
    <property>
        <name>yarn.scheduler.capacity.root.queue1.capacity</name>
        <value>50</value>
        <description>default queue target capacity.</description>
    </property>
    <property>
        <name>yarn.scheduler.capacity.root.queue2.capacity</name>
        <value>50</value>
        <description>default queue target capacity.</description>
    </property>
    <!-- 配置root队列可使用的标签资源占比 -->
    <property>
        <name>yarn.scheduler.capacity.root.accessible-node-labels.label1.capacity</name>
        <value>100</value>
    </property>
    <property>
        <name>yarn.scheduler.capacity.root.accessible-node-labels.label2.capacity</name>
        <value>100</value>
    </property>
    <!-- 配置queue1和queue2队列可使用的标签资源占比 -->
    <property>
        <name>yarn.scheduler.capacity.root.queue1.accessible-node-labels.label1.capacity</name>
        <value>100</value>
    </property>
    <property>
        <name>yarn.scheduler.capacity.root.queue2.accessible-node-labels.label2.capacity</name>
        <value>100</value>
    </property>
    <!-- 配置root队列可使用的标签 -->
    <property>
        <name>yarn.scheduler.capacity.root.accessible-node-labels</name>
        <value>*</value>
    </property>
    <!-- 配置queue1队列可使用的标签 -->
    <property>
        <name>yarn.scheduler.capacity.root.queue1.accessible-node-labels</name>
        <value>label1</value>
    </property>
    <!-- 配置queue2队列可使用的标签 -->
    <property>
        <name>yarn.scheduler.capacity.root.queue2.accessible-node-labels</name>
        <value>label2</value>
    </property>

</configuration>
~~~

重启resourcemanager

### flink启动命令变更

变更前

~~~
./flink run -m yarn-cluster -ys 1 -ynm cttde-alertEngine-waf /opt/hadoop/newjar/calculate-1.0.0-SNAPSHOT.jar -tenant waf -env sit
~~~

