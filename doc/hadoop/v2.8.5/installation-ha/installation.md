## Hadoop安装
<font color=red>tips1：本文档为 hadoop2.8.5 安装教程，如需安装其他版本，配置参数和安装过程可能会有所不同，请参考Hadoop官网文档进行操作</font>
https://hadoop.apache.org/docs/

<font color=green>tips2：文档中的 #{xxx} 是参数占位符，需根据实际情况进行替换</font>

### 1.下载并安装Java，后续安装都依赖


### 2.在官网下载需要版本的Hadoop安装包
* 创建 hadoop 集群归属的系统用户，如：`snsoadmin`（也可以直接使用`root`）
* 解压安装包至安装目录，如：`/data`
* 创建 临时目录、hdfs数据目录、日志目录、journaldata目录（仅journal服务节点） ，例：
  ~~~
  mkdir -p /data/hadoop/tmp
  mkdir -p /data/hadoop/hdfs/name
  mkdir -p /data/hadoop/hdfs/data
  mkdir -p /data/hadoop/logs
  mkdir -p /data/hadoop/journaldata
  ~~~
* 变更目录权限，例：
  ~~~
  chown -R snsoadmin:snsoadmin /data/hadoop
  ~~~


### 3.[系统环境设置](env.md)

### 4.[Zookeeper安装&配置](../../../zookeeper/v3.5.9/install-zookeeper.md)

### 4.[HDFS安装&配置](install-hdfs.md)

### 5.[YARN安装&配置](install-yarn.md)

### 6.[Flink安装&配置](install-flink.md)

