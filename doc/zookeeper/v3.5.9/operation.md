# zookeeper 数据恢复

<font color=orange>tips：本文介绍当 zookeeper 崩溃后如何最大限度的恢复数据，本文基于 3.5.9 版本，
如操作其他版本，过程可能会有所不同，请参考 zookeeper 官网文档</font>

正常运行的zookeeper的数据是存储在内存中的，但是为了保证zookeeper的数据一致性，引入了事务日志。

## zookeeper 的事务日志

事务日志指zookeeper系统在正常运行过程中，针对所有的更新操作，在返回客户端“更新成功”的响应前，zookeeper会保证已经将本次更新操作的事务日志已经写到磁盘上，只有这样，整个更新操作才会生效。

根据上文所述，可以通过`zoo.cfg`文件中的`dataLogDir`配置项找到事物日志存储目录

~~~
dataDir=/data/cloudytrace/clickhouse-zookeeper/zkdata
dataLogDir=/data/cloudytrace/clickhouse-zookeeper/zklogs
~~~

在`dataLogDir`下存在一个文件夹`version-2`，该文件夹中保存着事物日志文件:

~~~
-rw-rw-r-- 1 snsoadmin snsoadmin 1.8G May 21 19:31 log.30cac1e33d
-rw-rw-r-- 1 snsoadmin snsoadmin 1.8G May 21 22:32 log.30caed00b3
-rw-rw-r-- 1 snsoadmin snsoadmin 1.7G May 22 01:06 log.30cb188324
-rw-rw-r-- 1 snsoadmin snsoadmin 1.8G May 22 03:15 log.30cb3ed3ba
-rw-rw-r-- 1 snsoadmin snsoadmin 1.3G May 22 04:42 log.30cb672ace
-rw-rw-r-- 1 snsoadmin snsoadmin 1.4G May 22 06:19 log.30cb82cc8c
-rw-rw-r-- 1 snsoadmin snsoadmin 1.2G May 22 07:33 log.30cba188e0
-rw-rw-r-- 1 snsoadmin snsoadmin 1.0G May 22 08:39 log.30cbbb9674
-rw-rw-r-- 1 snsoadmin snsoadmin 1.4G May 22 10:29 log.30cbd3a378
-rw-rw-r-- 1 snsoadmin snsoadmin 1.4G May 22 12:30 log.30cbf38ebb
-rw-rw-r-- 1 snsoadmin snsoadmin 1.3G May 22 14:19 log.30cc14c6a2
~~~

以上我们可以看出，日志文件的命名规则为`log.**`，`**`表示写入该日志的第一个事务的ID，十六进制表示，这个ID对我们恢复数据非常中重要。

### 事务日志可视化

zookeeper 的事务日志为`二进制文件`，不能通过`vim`等工具直接访问。其实可以通过 zookeeper 自带的 jar包 读取事务日志文件。

首先将 libs 中的 slf4j-api-1.6.1.jar 文件和 zookeeper 根目录下的 zookeeper-3.4.9.jar 文件复制到临时文件夹 tmplibs
中，然后执行如下命令：

~~~
java -classpath .:slf4j-api-1.7.25.jar:zookeeper-3.5.9.jar org.apache.zookeeper.server.LogFormatter /data/cloudytrace/clickhouse-zookeeper/zklogs/version-2/log.30cac1e33d
~~~

## zookeeper 的 snapshot

zookeeper 的数据在`内存中以树形结构`进行存储的，而快照就是每隔一段时间就会把整个 DataTree 的数据序列化后存储在磁盘中，这就是
zookeeper 的快照文件。

zookeeper 快照日志的存储路径同样可以在`zoo.cfg`中查看，如上文截图所示。访问`dataDir`路径可以看到`version-2`文件夹:

~~~
-rw-rw-r-- 1 snsoadmin snsoadmin   2 Dec  9 15:39 acceptedEpoch
-rw-rw-r-- 1 snsoadmin snsoadmin   2 Dec  9 15:39 currentEpoch
-rw-rw-r-- 1 snsoadmin snsoadmin 64M May 21 19:31 snapshot.30caed00b1
-rw-rw-r-- 1 snsoadmin snsoadmin 62M May 21 22:32 snapshot.30cb188321
-rw-rw-r-- 1 snsoadmin snsoadmin 77M May 22 01:06 snapshot.30cb3ed3b8
-rw-rw-r-- 1 snsoadmin snsoadmin 79M May 22 03:15 snapshot.30cb672acb
-rw-rw-r-- 1 snsoadmin snsoadmin 76M May 22 04:42 snapshot.30cb82cc7f
-rw-rw-r-- 1 snsoadmin snsoadmin 77M May 22 06:19 snapshot.30cba188dd
-rw-rw-r-- 1 snsoadmin snsoadmin 85M May 22 07:33 snapshot.30cbbb9672
-rw-rw-r-- 1 snsoadmin snsoadmin 78M May 22 08:39 snapshot.30cbd3a370
-rw-rw-r-- 1 snsoadmin snsoadmin 75M May 22 10:29 snapshot.30cbf38eb9
-rw-rw-r-- 1 snsoadmin snsoadmin 65M May 22 12:30 snapshot.30cc14c69d
~~~

以上可以看出，zookeeper 快照文件的命名规则为`snapshot.**`，其中`**`表示 zookeeper 触发快照的那个瞬间，提交的最后一个事务的ID。

有了`事务日志`和`snapshot`我们就可以最大限度的恢复 zookeeper 的数据。

## zookeeper 集群数据恢复

假设zookeeper集群已经崩溃。我们可以参考以下步骤恢复数据。

1. 首先明确集群中各个机器存储`事务log`和`snapshot`的位置（参考`zoo.cfg`）
2. 分别找到集群中`事务id最大`的`log`和`snapshot`，`log`和`snapshot`的`后缀名`就是`事务id`，
   zookeeper 的`snapshot`是`全量数据的snapshot`， 后缀名表示最后一个写进`snapshot`的事务id，
   `log`的后缀名表示第一个写进`事务log`的事务id，所以理论上只要拿到`最大事务id`的`snapshot`和`log`，就可以最大程度的恢复集群的数据。
   由于集群的性质，最大事务id的`snapshot`和`log`很可能不在同一个节点，所以要查看集群的所有机器，备份之前先关掉集群，然后备份这两个文件。
3. 将集群中所有机器的`logs/version-2/`和`data/version-2`下的所有文件删除。
4. 将备份的文件分别copy到某一台机器的`logs/version-2/`和`data/version-2`下
5. 启动这台机器的 zookeeper
6. 启动其他节点的 zookeeper

