# ResourceManger Restart

## 特征

* 阶段1: Non-work-preserving RM restart

  从`Hadoop 2.4.0`版本开始，只实现了`ResourceManager Restart`阶段1，如下所述：

  总体概念是，当客户端提交应用程序时，RM将应用程序元数据(即ApplicationSubmissionContext)
  持久化在一个`可插拔的状态存储`中，并且还保存`应用程序的最终状态，例如完成状态(失败、终止、完成)`
  和`应用程序完成时的诊断`。此外，RM还保存了安全密钥、令牌等凭证，以便在安全的环境中工作。在RM关闭的任何时候，只要所需的信息(
  如在安全环境中运行的应用程序元数据和附带的凭据)
  在状态存储中可用，当RM重新启动时，它可以从状态存储中获取应用程序元数据并重新提交应用程序。如果应用程序在RM崩溃之前已经完成(
  即失败、终止、完成)，RM将不会重新提交。

  在RM停机期间，`nodemanager`和客户端将继续轮询RM，直到RM启动。当RM处于活动状态时，它将通过心跳向与之通信的所有`nodemanager`
  和`applicationmaster`发送重新同步命令。在`Hadoop 2.4.0`版本中，`nodemanager`和`applicationmaster`处理该命令的行为是:
  NMs将杀死其管理的所有容器并重新注册到RM。从RM的角度来看，这些重新注册的`nodemanager`类似于新加入的NMs。AMs(
  如`MapReduce AM`)在接收到`re-sync`
  命令后会关闭。RM重新启动并从状态存储中加载所有应用程序元数据、凭证并将它们填充到内存后，它将为每个尚未完成的应用程序创建一个新的尝试(
  即ApplicationMaster)
  ，并像往常一样重新启动该应用程序。如前所述，以前运行的应用程序的工作将以这种方式丢失，因为它们实际上是由RM通过重新启动时的`re-sync`
  命令杀死的。

* 阶段2: Work-preserving RM restart

  从`Hadoop 2.6.0`开始，进一步增强了RM重启功能，保证RM重启时不会杀死YARN集群上运行的任何应用程序。

  除了第一阶段所做的所有基础工作(确保应用程序状态的持久性并在恢复时重新加载该状态)
  之外，第二阶段主要侧重于重建YARN集群的整个运行状态，其中大部分是RM内部的中央调度器的状态，该调度器跟踪所有`容器`
  的`生命周期`、`应用程序的剩余空间和资源请求`、`队列的资源使用情况`等。
  通过这种方式，RM不需要像在阶段1一样终止AM并从头开始重新运行应用程序。应用程序可以简单地与RM重新同步，并从中断的地方恢复。

  RM通过利用从所有NMs发送的`容器状态`来恢复其运行状态。当NM与重启的RM重新同步时，它不会杀死容器。它继续管理容器，并在重新注册时将容器状态发送给RM。
  RM通过吸收这些容器的信息来重构容器实例和相关应用程序的调度状态。同时，AM需要将未完成的资源请求重新发送给RM，因为RM在关闭时可能会丢失未完成的请求。
  使用`AMRMClient库`与RM通信的应用程序编写者不需要担心AM在重新同步时将资源请求重新发送给RM的部分，因为它由库本身自动处理。

## 配置

### 启动RM重启

| 属性                                    | 描述   |
|---------------------------------------|------|
| yarn.resourcemanager.recovery.enabled | true |

### 配置状态存储以持久化RM状态

| 属性                               | 描述                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.resourcemanager.store.class | 用于保存应用程序/尝试状态和凭据的状态存储的类名。可用的状态存储实现是：<br/>基于ZooKeeper的状态存储实现：`org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore`<br/>基于Hadoop文件系统的状态存储实现（类似于HDFS和本地FS）：`org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore`<br/>基于LevelDB的状态存储实现：`org.apache.hadoop.yarn.server.resourcemanager.recovery.LeveldbRMStateStore`。<br/>默认值为`org.apache.hadoop.yarn.server.resourcemanager.recovery.FileSystemRMStateStore`。 |

### 如何选择状态存储实现

* 基于ZooKeeper的状态存储
  </br>用户可以自由选择任何存储来设置RM重启，<span style="color:red; ">
  但必须使用基于ZooKeeper的状态存储来支持`RM HA`</span>。
  原因是只有基于ZooKeeper的状态存储支持`隔离机制(fencing mechanism)`，以避免`脑裂情况`(
  多个RM认为自己是活的 & 同时编辑状态存储)。
* 基于FS的状态存储
  </br>支持HDFS和基于本地FS的状态存储。不支持隔离机制。
* 基于LevelDB的状态存储
  </br>比HDFS和基于ZooKeeper的状态存储更轻量级。LevelDB支持更好的原子操作，每次状态更新的I/O操作更少，文件系统上的文件总数更少。不支持隔离机制。

### 基于ZooKeeper的状态存储配置

* 配置`ZooKeeper服务器地址`和`RM状态所在的根路径`

| 属性                                              | 描述                                                                                              |
|-------------------------------------------------|-------------------------------------------------------------------------------------------------|
| yarn.resourcemanager.zk-address                 | 主机:端口对列表，以逗号分隔。每个对应一个ZooKeeper服务器(例如“127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002”)，用于RM存储RM状态。 |
| yarn.resourcemanager.zk-state-store.parent-path | 存放RM状态的根节点的完整路径。默认值为“/rmstore”。                                                                 |

* 配置`state-store client`连接ZooKeeper服务器时使用的`重试策略`

| 属性                                        | 描述                                                                                                   |
|-------------------------------------------|------------------------------------------------------------------------------------------------------|
| yarn.resourcemanager.zk-num-retries       | 如果连接丢失，RM尝试连接ZooKeeper服务器的次数。默认值为500。                                                                |
| yarn.resourcemanager.zk-retry-interval-ms | 连接ZooKeeper服务器时重试的时间间隔，以毫秒为单位。缺省值是2秒。                                                                |
| yarn.resourcemanager.zk-timeout-ms        | ZooKeeper会话超时时间(毫秒)。该配置用于ZooKeeper服务器判断会话何时过期。当服务器在此配置指定的会话超时时间内没有收到客户端的消息(即没有心跳)时，会话过期就会发生。缺省值是10秒。 |

* 配置ZooKeeper znode上用于设置权限的ACL

| 属性                          | 描述                                               |
|-----------------------------|--------------------------------------------------|
| yarn.resourcemanager.zk-acl | 用于设置ZooKeeper znodes的权限的ACL。缺省值为world:any:rwcda。 |

### 基于Hadoop文件系统的状态存储的配置

* 配置将RM状态保存在`Hadoop FileSystem`状态存储中的URI。

| 属性                                      | 描述                                                                                                                                                       |
|-----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.resourcemanager.fs.state-store.uri | 指向存储RM状态的文件系统路径位置的URI(例如hdfs://localhost:9000/rmstore)。默认值为${hadoop.tmp.dir}/yarn/system/rmstore。如果没有提供文件系统名称，将使用*conf/core-site.xml中指定的fs.default.name。 |

* 配置state-store客户端连接Hadoop文件系统的重试策略。

| 属性                                                    | 描述                                                                                                                                 |
|-------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| yarn.resourcemanager.fs.state-store.retry-policy-spec | Hadoop文件系统客户端重试策略规范。Hadoop文件系统客户端重试总是启用的。以睡眠时间和重试次数对指定，即(t0, n0)， (t1, n1)，…，前n次重试平均睡眠时间为0毫秒，后n1次重试平均睡眠时间为t1毫秒，依此类推。默认值是(2000,500) |

### 基于LevelDB的状态存储的配置

| 属性                                            | 描述                                                    |
|-----------------------------------------------|-------------------------------------------------------|
| yarn.resourcemanager.leveldb-state-store.path | 存储RM状态的本地路径。默认值为${hadoop.tmp.dir}/yarn/system/rmstore |

### work-preserving RM恢复的配置

| 属性                                                               | 描述                                                                          |
|------------------------------------------------------------------|-----------------------------------------------------------------------------|
| yarn.resourcemanager.work-preserving-recovery.scheduling-wait-ms | 在`work-preserving`恢复分配新容器前，设置RM的等待时间。使RM有机会在恢复时与集群中的NMs重新同步，然后再将新容器分配给应用程序。 |

## 备注

如果RM重启并启用 work-preserving recovery，则ContainerId字符串格式将被修改。

以前的格式：`Container_{clusterTimestamp}_{appId}_{attemptId}_{containerId}`
，如 `Container_1410901177871_0001_01_000005`.
<br/>改变后格式: `Container_e{epoch}_{clusterTimestamp}_{appId}_{attemptId}_{containerId}`, 如
`Container_e17_1410901177871_0001_01_000005`.

这里，额外的epoch数是一个单调递增的整数，从0开始，每次RM重启时增加1。如果epoch number为0，则省略，containerId字符串格式保持不变。

## 配置样例

~~~
 <property>
   <name>yarn.resourcemanager.recovery.enabled</name>
   <value>true</value>
 </property>

 <property>
   <name>yarn.resourcemanager.store.class</name>
   <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
 </property>

 <property>
   <name>yarn.resourcemanager.zk-address</name>
   <value>127.0.0.1:2181</value>
 </property>
~~~

[yarn安装样例](../../installation-ha/install-yarn.md)

