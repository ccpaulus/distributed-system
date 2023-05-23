# Standard Setup

agent 是使用名为 `flume-ng` 的 shell脚本 启动的，该脚本位于 Flume 发行版的 `bin` 目录中。您需要在命令行中指定 agent
名称、配置目录和配置文件

~~~
$ bin/flume-ng agent -n $agent_name -c conf -f conf/flume-conf.properties.template
~~~

agent 将开始运行在给定属性文件中配置的 source 和 sink。

## 1.简单例子

在这里，我们给出一个示例配置文件，描述一个单节点Flume部署。此配置允许用户生成事件并随后将其记录到控制台。

~~~
# example.conf: A single-node Flume configuration

# Name the components on this agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source
a1.sources.r1.type = netcat
a1.sources.r1.bind = localhost
a1.sources.r1.port = 44444

# Describe the sink
a1.sinks.k1.type = logger

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
~~~

### 启动 Flume agent

~~~
$ bin/flume-ng agent --conf conf --conf-file example.conf --name a1
~~~

注意，在完整部署中，我们通常会包含一个选项:`--conf=<conf-dir>`。`<conf-dir>`目录将包括 `一个shell脚本 flume-env.sh`
和 `一个log4j配置文件`。

### 发送事件

然后，从一个单独的终端，我们可以 telnet 端口 44444 并向 Flume 发送一个事件

~~~
$ telnet localhost 44444
Trying 127.0.0.1...
Connected to localhost.localdomain (127.0.0.1).
Escape character is '^]'.
Hello world! <ENTER>
OK
~~~

### Sink 输出

Flume 终端 将以日志消息的形式输出事件。

~~~
12/06/19 15:32:19 INFO source.NetcatSource: Source starting
12/06/19 15:32:19 INFO source.NetcatSource: Created serverSocket:sun.nio.ch.ServerSocketChannelImpl[/127.0.0.1:44444]
12/06/19 15:32:34 INFO sink.LoggerSink: Event: { headers:{} body: 48 65 6C 6C 6F 20 77 6F 72 6C 64 21 0D          Hello world!. }
~~~

## 2.多个配置文件

每个文件都应该使用自己的 conf-file 或 conf-uri 选项来配置。但是，所有文件都应该使用 conf-file 或 conf-uri 提供。
如果 conf-file 和 conf-uri 同时作为选项出现，所有 conf-uri 配置将在任意 conf-file 配置被合并之前被处理。

~~~
$ bin/flume-ng agent --conf conf --conf-file example.conf --conf-uri http://localhost:80/flume.conf --conf-uri http://localhost:80/override.conf --name a1
~~~

如上，将使得 flume.conf 首先被读取，然后 override.conf 与之合并，example.conf最后被合并。如果希望将example.conf作为基本配置，则应该使用conf-uri选项指定：

~~~
--conf-uri classpath://example.conf
or
--conf-uri file:///example.conf
~~~

## 3.使用环境变量、系统属性 或 其他属性配置文件

### 环境变量

    ~~~
    a1.sources = r1
    a1.sources.r1.type = netcat
    a1.sources.r1.bind = 0.0.0.0
    a1.sources.r1.port = ${env:NC_PORT}
    a1.sources.r1.channels = c1
    ~~~

### 系统属性

    ~~~
    a1.sources = r1
    a1.sources.r1.type = netcat
    a1.sources.r1.bind = 0.0.0.0
    a1.sources.r1.port = ${sys:NC_PORT}
    a1.sources.r1.channels = c1
    ~~~

### 多个配置文件

文件1：

~~~
a1.sources = r1
a1.sources.r1.type = netcat
a1.sources.r1.bind = 0.0.0.0
a1.sources.r1.port = ${NC_PORT}
a1.sources.r1.channels = c1
~~~

文件2（需要包含文件1中变量）：

~~~
NC_PORT = 44444
~~~

#### 启动命令：

~~~
$ bin/flume-ng agent --conf conf --conf-file example.conf --conf-file override.conf --name a1
~~~

## 4.记录原始数据

在许多生产环境中，记录流经摄取管道的原始数据流并不是理想的行为，因为这可能导致敏感数据或安全相关配置(如密钥)泄露到 Flume
日志文件中。 默认情况下，Flume不会记录此类信息。然而，如果数据管道被破坏，Flume 需要为调试问题提供线索。

调试事件管道问题的一种方法是建立一个连接到 Logger Sink 的额外 Memory Channel，它将把所有事件数据输出到 Flume
日志中。然而，在某些情况下，这种方法是不够的。

为了启用事件和配置相关数据的日志记录，除了 log4j 属性之外，还必须设置一些 Java 系统属性。

要启用与配置相关的日志记录，请设置 Java 系统属性 `-Dorg.apache.flume.log.printconfig=true`
。这可以在命令行上传递，也可以在 flume-env.sh 的 JAVA OPTS 变量中设置。

要启用数据记录，请设置Java系统属性 `-Dorg.apache.flume.log.rawdata=true`
。对于大多数组件，log4j 日志级别还必须设置为 DEBUG 或 TRACE，以便在 Flume 日志中显示特定于事件的日志。

下面是同时启用配置日志记录和原始数据日志记录的示例：

~~~
$ bin/flume-ng agent --conf conf --conf-file example.conf --name a1 -Dorg.apache.flume.log.printconfig=true -Dorg.apache.flume.log.rawdata=true
~~~

## 5.基于Zookeeper的配置

Flume 支持通过 Zookeeper 进行 Agent 配置。这是一个`实验性`的功能。配置文件需要上传到 Zookeeper 中，在一个可配置的前缀下。
配置文件保存在 `Zookeeper Node data` 中。下面是 a1 和 a2 的 Zookeeper 节点树的样子

~~~
- /flume
 |- /a1 [Agent config file]
 |- /a2 [Agent config file]
~~~

### 启动

~~~
$ bin/flume-ng agent –conf conf -z zkhost:2181,zkhost1:2181 -p /flume –name a1
~~~

