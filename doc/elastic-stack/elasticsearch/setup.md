# ElasticSearch 安装&配置

<font color=red>tips1：本文档为 ElasticSearch7.8.1
安装教程，如需安装其他版本，配置参数和安装过程可能会有所不同，请参考 Elastic 官网文档进行操作</font>
<br/>官网地址
https://www.elastic.co/guide/en/elasticsearch/reference/7.8/index.html

## 1、[介绍](what-is-elasticsearch.md)

## 2、下载&安装

~~~
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.1-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.1-linux-x86_64.tar.gz.sha512
shasum -a 512 -c elasticsearch-7.8.1-linux-x86_64.tar.gz.sha512
tar -xzf elasticsearch-7.8.1-linux-x86_64.tar.gz
cd elasticsearch-7.8.1/
~~~

### 目录结构

| 目录      | 描述                                               | 默认位置             | 配置项          |
|---------|--------------------------------------------------|------------------|--------------|
| home    | Elasticsearch home目录 或 $ES home                  | 解压创建             |              |
| bin     | 二进制脚本，包括启动节点和安装插件                                | $ES_HOME/bin     |              |
| conf    | 配置文件包括elasticsearch.yml                          | $ES_HOME/config  | ES_PATH_CONF |
| data    | 节点上分配的每个 index / shard 的数据文件的位置，可以容纳多个位置         | $ES_HOME/data    | path.data    |
| logs    | 日志文件位置                                           | $ES_HOME/logs    | path.logs    |
| plugins | 插件文件位置，每个插件将包含在一个子目录中                            | $ES_HOME/plugins |              |
| repo    | 共享文件系统存储库位置。可以容纳多个位置。文件系统存储库可以放在这里指定的任何目录的任何子目录中 | 未配置              | path.repo    |

## 3、[配置](config/conf-elasticsearch.md)

## 4、启动 Elasticsearch（作为守护进程）

~~~
# 使用-p选项在文件中记录进程ID
./bin/elasticsearch -d -p pid
~~~

## 5、关闭 Elasticsearch

~~~
# 杀死pid文件中记录的进程ID
pkill -F pid
~~~

