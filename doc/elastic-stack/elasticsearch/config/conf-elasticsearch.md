# 配置 Elasticsearch

## 配置分类

* Elasticsearch 配置文件
  <br/>配置文件目录，默认：`$ES_HOME/config`，可通过设置环境变量`ES_PATH_CONF`进行变更
  <br/>适用于`静态settings`，配置后需要重启节点服务
    * elasticsearch.yml： Elasticsearch 配置
    * jvm.options：Elasticsearch JVM 配置
    * log4j2.properties：Elasticsearch 日志配置

* [Cluster update settings API](https://www.elastic.co/guide/en/elasticsearch/reference/7.8/cluster-update-settings.html)
  <br/>适用于`动态settings`，配置后立即生效

<font color=red>tips：集群范围设置最好使用`cluster update settings API`,可确保所有节点上的设置相同；
而使用elasticsearch.yml仅用于本地配置，如果不小心在不同的节点上的elasticsearch.yml中配置了不同的设置，是很难发现差异的</font>

--------------------------------------------------------------------------------------

## 各类配置详情

以下仅常用配置提供说明，其他可参考 [官网配置说明](https://www.elastic.co/guide/en/elasticsearch/reference/7.8/settings.html)
<br/>其中`X-Pack`
为官方增强插件包，部分免费，部分收费，具体请查阅 [Elastic Stack 订阅](https://www.elastic.co/cn/subscriptions)

* [Setting JVM options](conf-jvm.md)
* Secure settings
* Auditing settings`X-Pack`
* Circuit breaker settings
* [Cluster-level shard allocation and routing settings]()
* Cross-cluster replication settings
* Discovery and cluster formation settings
* Field data cache settings
* HTTP
* Index lifecycle management settings
* Index management settings
* Index recovery settings
* Indexing buffer settings
* License settings
* Local gateway settings
* Logging configuration
* Machine learning settings
* Monitoring settings
* Node
* Network settings
* Node query cache settings
* Search settings
* Security settings
* Shard request cache settings
* Snapshot lifecycle management settings
* Transforms settings
* Transport
* Thread pools
* Watcher settings