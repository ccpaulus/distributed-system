# Metric Reporters

Flink 支持用户将 Flink 的各项运行时指标发送给外部系统。 了解更多指标方面信息可查看 metric 系统相关文档。

你可以通过 `conf/flink-conf.yaml` 文件来配置一种或多种发送器，将运行时指标暴露给外部系统。 发送器会在 TaskManager、Flink
作业启动时进行实例化。

下面列出了所有发送器都适用的参数，可以通过配置文件中的 `metrics.reporter.<reporter_name>.<property>`
项进行配置。有些发送器有自己特有的配置，详见该发送器章节下的具体说明。

| **键**                      | **默认值** | **数据类型**     | **描述**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|----------------------------|---------|--------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| factory.class              | (none)  | String       | 命名为 <name> 发送器的工厂类名称。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| interval                   | 10 s    | Duration     | 命名为 <name> 发送器的发送间隔，只支持 push 类型发送器。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| scope.delimiter            | "."     | String       | 命名为 <name> 发送器的指标标识符中的间隔符。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| scope.variables.additional |         | Map          | 命名为 <name> 发送器的 map 形式的变量列表，只支持 tags 类型发送器。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| scope.variables.excludes   | "."     | String       | 命名为 <name> 发送器应该忽略的一组变量，只支持 tags 类型发送器。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| filter.includes            | "*:*:*" | List<String> | 命名为 <name> 发送器应包含的运行指标，其过滤条件以列表形式表示，该列表中每一个过滤条件都应遵循如下规范：`<scope>[:<name>[,<name>][:<type>[,<type>]]]`<br/><br/> * 范围： 指过滤条件中指标所属的逻辑范围。<br/>以如下模式进行匹配：* 代表所有字符都匹配。. 划分范围的层级。<br/>例如："jobmanager.job" 匹配出 JobManager 上运行的所有 job 相关的指标，"*.job" 匹配出所有 job 相关的指标，"*.job.*" 匹配 job 级别下的指标（例如运行的作业、算子等）。<br/><br/> * 名称： 指过滤条件中指标的名称。<br/>按照以逗号分割的模式列表作进行匹配，其中 * 匹配所有字符。<br/>例如， "*Records*,*Bytes*" 会匹配所有指标名字中带有 "Records" 或者 "Bytes" 的指标。<br/><br/> * 类型：指过滤条件中指标所属的指标类型。按照以逗号分割的指标类型列表作进行匹配：[counter, meter, gauge, histogram]<br/><br/>例如：<br/> * "*:numRecords*" 会匹配带有 numRecordsIn 的指标。<br/>* "*.job.task.operator:numRecords*" 会在运行作业的算子级别匹配带有 numRecordsIn 的指标。<br/>* "*.job.task.operator:numRecords*:meter" 会在运行作业的算子级别匹配带有 numRecordsInPerSecond 的 meter 类型指标。<br/>* "*:numRecords*,numBytes*:counter,meter" 会匹配所有指标名字中带有 numRecordsInPerSecond 的 counter 或 meter 类型的指标。 |
| filter.excludes            |         | List<String> | 命名为 <name> 发送器应排除掉的运行指标，形式与 filter.includes 类似。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| <parameter>                | (none)  | String       | 配置命名为 <name> 发送器的 <parameter> 项                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |

每种发送器的配置需要有 factory.class 属性。 有些基于定时调度的发送器还可以通过 interval 来配置发送间隔。

想要同时配置多个发送器，可参考以下示例。

~~~
metrics.reporters: my_jmx_reporter,my_other_reporter

metrics.reporter.my_jmx_reporter.factory.class: org.apache.flink.metrics.jmx.JMXReporterFactory
metrics.reporter.my_jmx_reporter.port: 9020-9040
metrics.reporter.my_jmx_reporter.scope.variables.excludes: job_id;task_attempt_num
metrics.reporter.my_jmx_reporter.scope.variables.additional: cluster_name:my_test_cluster,tag_name:tag_value

metrics.reporter.my_other_reporter.factory.class: org.apache.flink.metrics.graphite.GraphiteReporterFactory
metrics.reporter.my_other_reporter.host: 192.168.1.1
metrics.reporter.my_other_reporter.port: 10000
~~~

**注意：**Flink 在启动时必须能访问到发送器所属的 jar 包，发送器会被加载为 [plugins]()，Flink
自带的发送器（文档中已经列出的发送器）无需做其他配置，开箱即用。

你可以实现 org.apache.flink.metrics.reporter.MetricReporter 接口来自定义发送器，并实现 Scheduled 接口让发送器周期性地将运行时指标发送出去。
需要注意 report() 方法不应该阻塞太长的时间，所有用时很长的操作应该异步执行。 另外也可以实现 MetricReporterFactory
接口，让发送器作为插件被 Flink 导入。

## 基于标志符格式 vs. 基于 tags 格式

发送器发送运行指标时有以下两种格式：

第一种是基于标志符的格式，这种格式将指标所属的详细范围信息与该指标名称连在一起，组成一个长字符串标志符。 比如
job.MyJobName.numRestarts 就是这样的格式。

第二种是基于 tags 的格式，这种格式由指标的逻辑范围和该指标名称组成，代表某一类通用的指标，比如 job.numRestarts。
这类格式描述的特定指标实例会以“键值对”的方式体现出来，即所谓的标签或变量，比如 “jobName=MyJobName”。

## Push vs. Pull

发送器通过 Pull 或 Push 的方式将指标发送出去。

基于 Push 的发送器一般实现了 Scheduled 接口，周期性地将当前运行指标信息汇总，发送给外部系统存储。

基于 Pull 的发送器一般是由外部系统主动发起查询将指标信息拉走。

## 发送器

接下来的部分列出了 Flink 支持的发送器。

### JMX

#### (org.apache.flink.metrics.jmx.JMXReporter)

类型: pull/基于 tags 格式

参数：

port -（可选的）JMX 监听的端口。 如果需要在一台机器上运行多个发送器示例进行监控时（比如 TaskManger 与 JobManager
在一台机器上运行时），建议将端口号配置为 9250-9260 这样的区间， 实际使用的端口会在相关作业 或 TaskManger
的日志中显示。如果设置了这个选项，Flink 会按照配置的端口号或端口区间开启 JMX 发送器， 这些运行时指标可以通过本地的 JMX
默认接口访问到。
配置示例：

~~~
metrics.reporter.jmx.factory.class: org.apache.flink.metrics.jmx.JMXReporterFactory
metrics.reporter.jmx.port: 8789
~~~

通过 JMX 发送的指标由“域”和“key-properties”列表组成，“域”总以 org.apache.flink 开头，后跟一个“通用指标标识符”。

“通用指标标识符”不像一般系统的指标度量那样按照所度量范围的形式进行命名，而是不包含任何变量，如同常量一样，每个作业都有。
例如，org.apache.flink.job.task.numBytesOut 就是一个“域”。

“key-property”列表包含所有指标的具体变量值，无论配置的度量范围格式如何，都能关联到指定的指标。

例如host=localhost,job_name=MyJob,task_name=MyTask 就是一个“key-property”列表。

总结来说，“域”标注出了某个指标的类，“key-property”列表标注出了该指标的一个（或者多个）实例。

### Graphite

#### (org.apache.flink.metrics.graphite.GraphiteReporter)

类型: push/基于标志符格式

参数：

* host - Graphite 服务的地址。
* port - Graphite 服务的端口。
* protocol - 使用的协议（TCP/UDP）。
  配置示例：

~~~
metrics.reporter.grph.factory.class: org.apache.flink.metrics.graphite.GraphiteReporterFactory
metrics.reporter.grph.host: localhost
metrics.reporter.grph.port: 2003
metrics.reporter.grph.protocol: TCP
metrics.reporter.grph.interval: 60 SECONDS
~~~

### InfluxDB

#### (org.apache.flink.metrics.influxdbPrometheusPushGateway.InfluxdbReporter)

类型: push/基于 tags 格式

参数：

| **键**           | **默认值** | **数据类型** | **描述**                                                                                            |
|-----------------|---------|----------|---------------------------------------------------------------------------------------------------|
| connectTimeout  | 10000   | Integer  | （可选的）连接 InfluxDB 时的超时时间。                                                                          |
| consistency     | ONE     | Enum     | （可选的）InfluxDB 保存指标时的一致性级别。<br/><br/> 可选的值：<br/> * "ALL"<br/> * "ANY"<br/> * "ONE"<br/> * "QUORUM" |
| db              | (none)  | String   | 存储运行指标的 InfluxDB 数据库名称。                                                                           |
| host            | (none)  | String   | InfluxDB 服务器的地址。                                                                                  |
| password        | (none)  | String   | （可选的）验证 InfluxDB 时用户名的密码。                                                                         |
| port            | 8086    | Integer  | InfluxDB 服务器的端口号。                                                                                 |
| retentionPolicy | (none)  | String   | （可选的）InfluxDB 保存指标时使用的保留策略。                                                                       |
| scheme          | http    | Enum     | InfluxDB 使用的协议。<br/><br/> 可选的值：<br/> * "http"<br/> * "https"<br/>                                 |
| username        | (none)  | String   | （可选的）验证 InfluxDB 时的用户名。                                                                           |
| writeTimeout    | 10000   | Integer  | （可选的）InfluxDB 的写入超时时间。                                                                            |

配置示例：

~~~
metrics.reporter.influxdb.factory.class: org.apache.flink.metrics.influxdb.InfluxdbReporterFactory
metrics.reporter.influxdb.scheme: http
metrics.reporter.influxdb.host: localhost
metrics.reporter.influxdb.port: 8086
metrics.reporter.influxdb.db: flink
metrics.reporter.influxdb.username: flink-metrics
metrics.reporter.influxdb.password: qwerty
metrics.reporter.influxdb.retentionPolicy: one_hour
metrics.reporter.influxdb.consistency: ANY
metrics.reporter.influxdb.connectTimeout: 60000
metrics.reporter.influxdb.writeTimeout: 60000
metrics.reporter.influxdb.interval: 60 SECONDS
~~~

InfluxDB 发送器会使用 http 协议按照将指标发送到 InfluxDB 服务器。指标的保留策略可通过配置指定，或按照 InfluxDB 服务端的保留策略决定。
所有的 Flink 运行指标变量（见 [List of all Variables]()）都会按照 tag 形式上报给 InfluxDB。

### Prometheus

#### (org.apache.flink.metrics.prometheus.PrometheusReporter)

类型: pull/基于 tags 格式

参数：

* port - （可选的）Prometheus 发送器监听的端口，默认为 [9249]()。如果需要在一台机器上运行多个发送器示例进行监控时（比如
  TaskManger 与 JobManager 在一台机器上运行时），建议将端口号配置为 9250-9260 这样的区间。
* filterLabelValueCharacters -（可选的）指定是否过滤 label 中的非法字符。如果设置过滤，所有没有按照 [a-zA-Z0-9:_]
  匹配的字符都会被过滤掉，如果设置不过滤，则不会有字符被过滤掉。设置不过滤前，请确保你的 label
  符合 [Prometheus 的 lable 命名规范]()。
  配置示例：

~~~
metrics.reporter.prom.factory.class: org.apache.flink.metrics.prometheus.PrometheusReporterFactory
~~~

Flink 指标类型与 Prometheus 指标类型对应关系如下：

| **Flink** | **Prometheus** | **注意事项**                           |
|-----------|----------------|------------------------------------|
| Counter   | Gauge          | Prometheus 的 counter 不支持累加。        |
| Gauge     | Gauge          | 只支持数字与布尔类型。                        |
| Histogram | Summary        | 分位数为 .5，.75，.95，.98，.99 和 .999。    |
| Meter     | Gauge          | Prometheus 的 gauge 为 meter 的百分比形式。 |

所有的 Flink 运行指标变量（见 [List of all Variables]()）都会按照 label 形式上报给 Prometheus。

### PrometheusPushGateway

#### (org.apache.flink.metrics.prometheus.PrometheusPushGatewayReporter)

类型: push/基于 tags 格式

参数：

| **键**                      | **默认值** | **数据类型** | **描述**                                                                                                                   |
|----------------------------|---------|----------|--------------------------------------------------------------------------------------------------------------------------|
| deleteOnShutdown           | true    | Boolean  | 是否在 PushGateway 停止运行时删除指标数据，Flink 会尽最大可能性删除指标数据（不保证一定能删除），更多细节请查看 [此链接]()。                                               |
| filterLabelValueCharacters | true    | Boolean  | 是否过滤 label 中的字符。如果设置过滤，所有没有按照 \[a-zA-Z0-9:_\] 匹配的字符都会被过滤掉，如果设置不过滤，则不会有字符被过滤掉。设置不过滤前，请确保你的 label 符合 [Prometheus 的命名规范]()。 |
| groupingKey                | (none)  | String   | 指定分组键，作为所有指标的组和全局标签。标签名称与值之间用 '=' 分割，标签与标签之间用 ';' 分隔，比如 k1=v1;k2=v2 。请确保你的分组键符合 [Prometheus 的命名规范]()。                    |
| hostUrl                    | (none)  | String   | PushGateway 服务器的 URL，包括协议、服务地址、端口号。                                                                                      |
| jobName                    | (none)  | String   | 推送运行指标数据时的作业名。                                                                                                           |
| randomJobNameSuffix        | true    | Boolean  | 是否在作业名后添加一个随机后缀。                                                                                                         |

配置示例：

~~~
metrics.reporter.promgateway.factory.class: org.apache.flink.metrics.prometheus.PrometheusPushGatewayReporterFactory
metrics.reporter.promgateway.hostUrl: http://localhost:9091
metrics.reporter.promgateway.jobName: myJob
metrics.reporter.promgateway.randomJobNameSuffix: true
metrics.reporter.promgateway.deleteOnShutdown: false
metrics.reporter.promgateway.groupingKey: k1=v1;k2=v2
metrics.reporter.promgateway.interval: 60 SECONDS
~~~

PrometheusPushGatewayReporter 发送器将运行指标发送给 [Pushgateway]()，Prometheus 再从 Pushgateway 拉取、解析运行指标。

更多使用方法可查看 [Prometheus 的文档]()

### StatsD

#### (org.apache.flink.metrics.statsd.StatsDReporter)

类型: push/基于标志符格式

参数：

* host - StatsD 的服务器地址。
* port - StatsD 的服务器端口。
  配置示例：

~~~
metrics.reporter.stsd.factory.class: org.apache.flink.metrics.statsd.StatsDReporterFactory
metrics.reporter.stsd.host: localhost
metrics.reporter.stsd.port: 8125
metrics.reporter.stsd.interval: 60 SECONDS
~~~

### Datadog

#### (org.apache.flink.metrics.datadog.DatadogHttpReporter)

类型: push/基于 tags 格式

使用 Datadog 时，Flink 运行指标中的任何变量，例如 <host>、<job_name>、 <tm_id>、 <subtask_index>、<task_name>、 <operator_name>
，都会被当作 host:localhost、job_name:myjobname 这样的 tag 发送。

Note For legacy reasons the reporter uses both the metric identifier and tags. This redundancy can be avoided by
enabling useLogicalIdentifier.

注意 按照 Datadog 的 Histograms 命名约定，Histograms 类的运行指标会作为一系列 gauges 显示（<metric_name>.<aggregation>）。
默认情况下 min 即最小值被发送到 Datadog，sum 不会被发送。 与 Datadog 提供的 Histograms 相比，Histograms
类的运行指标不会按照指定的发送间隔进行聚合计算。

参数:

* apikey - Datadog 的 API KEY。
* proxyHost - （可选的）发送到 Datadog 时使用的代理主机。
* proxyPort - （可选的）发送到 Datadog 时使用的代理端口，默认为 8080。
* dataCenter - （可选的）要连接的数据中心（EU/US），默认为 US。
* maxMetricsPerRequest - （可选的）每次请求携带的最大运行指标个数，默认为 2000。
* useLogicalIdentifier -> (optional) Whether the reporter uses a logical metric identifier, defaults to false.
  配置示例:

~~~
metrics.reporter.dghttp.factory.class: org.apache.flink.metrics.datadog.DatadogHttpReporterFactory
metrics.reporter.dghttp.apikey: xxx
metrics.reporter.dghttp.proxyHost: my.web.proxy.com
metrics.reporter.dghttp.proxyPort: 8080
metrics.reporter.dghttp.dataCenter: US
metrics.reporter.dghttp.maxMetricsPerRequest: 2000
metrics.reporter.dghttp.interval: 60 SECONDS
metrics.reporter.dghttp.useLogicalIdentifier: true
~~~

### Slf4j

#### (org.apache.flink.metrics.slf4j.Slf4jReporter)

类型: push/基于标志符格式

配置示例:

~~~
metrics.reporter.slf4j.factory.class: org.apache.flink.metrics.slf4j.Slf4jReporterFactory
metrics.reporter.slf4j.interval: 60 SECONDS
~~~

