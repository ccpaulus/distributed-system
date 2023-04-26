# HDFS

[官方文档地址](https://hadoop.apache.org/docs/r2.8.5/)

* [Architecture](hdfs-arch.md)
* [User Guide](https://hadoop.apache.org/docs/r2.8.5/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html)
* [Commands Reference](https://hadoop.apache.org/docs/r2.8.5/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html)
* [NameNode HA With QJM](namenode-ha-with-qjm.md)
* NameNode HA With NFS：推荐使用`NameNode HA With QJM]`
* [Federation](federation.md)
* ViewFs：提供了一种管理多个Hadoop文件系统命名空间(或命名空间卷)的方法。在HDFS Federation中，它对于具有多个命名节点和多个命名空间的集群特别有用。
  ViewFs类似于某些Unix/Linux系统中的客户端挂载表。ViewFs可用于创建个性化的名称空间视图和每个集群的公共视图。一个namenode访问到所有namenode的路径。
* Snapshots
  <br/>HDFS快照，灾备用，默认不开启。
* Edits Viewer
  <br/>`Offline Edits Viewer`是解析编辑`Edits log`的工具。主要用于不同格式之间的转换，包括XML，比原生二进制格式更容易编辑。
* Image Viewer
  <br/>`Offline Image Viewer`是一个将`hdfs fsimage`文件的内容转储为人类可读格式的工具，并提供只读的`WebHDFS API`
  ，以便允许离线分析和检查Hadoop集群的namespace。
* Permissions and HDFS
  <br/>Hadoop分布式文件系统(HDFS)为文件和目录实现了一个权限模型，该模型类似POSIX模型。每个文件和目录都与一个所有者和一个组相关联。
  对于作为所有者的用户、作为组成员的其他用户以及所有其他用户，文件或目录具有单独的权限。对于文件，读文件需要r权限，写文件或追加文件需要w权限。
  对于目录，列出目录的内容需要r权限，创建或删除文件或目录需要w权限，访问目录的子目录需要x权限。
* Quotas and HDFS
  <br/>设置HDFS目录配额，文件数 | 字节数。
* HFTP（弃用）
* libhdfs (C API)
  <br/>操作HDFS文件和文件系统的`C API`。
* WebHDFS (REST API)
  <br/>`HTTP REST API`支持HDFS完整的FileSystem/FileContext接口，对HDFS进行操作；HDFS内置，直接通信datanode。
* HttpFS
  <br/>提供一个REST HTTP网关，支持所有HDFS文件系统操作(读和写)；单独安装，该服务作为通信datanode的网关。
* Short Circuit Local Reads
  <br/>在HDFS中，读取通常要经过DataNode。因此，当客户机请求DataNode读取文件时，DataNode从磁盘读取该文件，并通过TCP套接字将数据发送给客户机。
  所谓的“短路”读取绕过DataNode，允许客户机直接读取文件。只有在客户端与数据位于同一位置的情况下才有效。短路读取为许多应用程序提供了实质性的性能提升。
* Centralized Cache Management
  <br/>HDFS的集中式缓存管理是一种显式的缓存机制，允许用户指定要被HDFS缓存的路径。NameNode将与磁盘上有所需块的datanode通信，并指示它们将块缓存到堆外缓存中。
  显式指定可防止经常使用的数据从内存中被驱逐，支持零拷贝读，提高读取性能。
* NFS Gateway
  <br/>NFS网关支持NFSv3，并允许将HDFS作为客户端本地文件系统的一部分挂载。
* Rolling Upgrade
* Extended Attributes
  仿照Linux中的扩展属性建模，允许用户应用程序将额外的`元数据`与`HDFS文件或目录`关联
* Transparent Encryption
  <br/>端到端数据加密
* Multihoming
  <br/>HDFS对多宿主网络的支持
* Storage Policies
  <br/>标记不同介质的存储（读写速度、大小不同），提供用户自行选择使用，哪些用于计算、用于存储
* Memory Storage Support
  <br/>
  datanode将内存中的数据异步刷新到磁盘，从而从性能敏感的IO路径中删除昂贵的磁盘IO和校验和计算，这种写被称为`Lazy Persist`
  写。
  