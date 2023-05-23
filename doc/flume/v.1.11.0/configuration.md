# Configuration

标准的 Flume agent 配置是从一个类似于具有分层属性设置的 Java 属性文件格式的文件中读取的。

## 定义流（Defining the flow）

要在单个 agent 中定义流，需要通过 channel 链接 sources 和 sinks。
您需要列出给定 agent 的 sources、sinks 和 channels，然后将 source 和 sink 指向一个 channel。
source 实例 可以指定多个 channels，但 sink 实例 只能指定一个 channel。格式如下：

~~~
# list the sources, sinks and channels for the agent
<Agent>.sources = <Source>
<Agent>.sinks = <Sink>
<Agent>.channels = <Channel1> <Channel2>

# set channel for source
<Agent>.sources.<Source>.channels = <Channel1> <Channel2> ...

# set channel for sink
<Agent>.sinks.<Sink>.channel = <Channel1>
~~~

例如，一个名为 agent_foo 的 agent 正在从外部 avro客户端 读取数据，并通过 memory channel 将其发送到 HDFS。
配置文件如下所示：

~~~
# list the sources, sinks and channels for the agent
agent_foo.sources = avro-appserver-src-1
agent_foo.sinks = hdfs-sink-1
agent_foo.channels = mem-channel-1

# set channel for source
agent_foo.sources.avro-appserver-src-1.channels = mem-channel-1

# set channel for sink
agent_foo.sinks.hdfs-sink-1.channel = mem-channel-1
~~~

事件 通过 mem-channel-1 从 avro-appserver-src-1 流到 hdfs-sink-1。当 agent 使用该配置启动时，它将实例化该流。

## 配置单个组件

定义流之后，您需要设置每个 source、 sink 和 channel 的属性。这是通过相同的层次命名空间方式完成的，您可以为每个组件特定的属性设置组件类型和其他值：

~~~
# properties for sources
<Agent>.sources.<Source>.<someProperty> = <someValue>

# properties for channels
<Agent>.channels.<Channel>.<someProperty> = <someValue>

# properties for sinks
<Agent>.sinks.<Sink>.<someProperty> = <someValue>
~~~

每个组件都要设置属性`type`，以便 Flume 了解它需要的对象类型。每个 source、 sink 和 channel 类型都有自己的一组属性，以便按预期的方式工作。
所有这些都需要根据需要进行设置。下面的示例显示了每个组件的配置：

~~~
agent_foo.sources = avro-AppSrv-source
agent_foo.sinks = hdfs-Cluster1-sink
agent_foo.channels = mem-channel-1

# set channel for sources, sinks

# properties of avro-AppSrv-source
agent_foo.sources.avro-AppSrv-source.type = avro
agent_foo.sources.avro-AppSrv-source.bind = localhost
agent_foo.sources.avro-AppSrv-source.port = 10000

# properties of mem-channel-1
agent_foo.channels.mem-channel-1.type = memory
agent_foo.channels.mem-channel-1.capacity = 1000
agent_foo.channels.mem-channel-1.transactionCapacity = 100

# properties of hdfs-Cluster1-sink
agent_foo.sinks.hdfs-Cluster1-sink.type = hdfs
agent_foo.sinks.hdfs-Cluster1-sink.hdfs.path = hdfs://namenode/flume/webdata

#...
~~~

## 在一个 agent 中添加多个流

一个Flume代理可以包含几个独立的流。你可以在一个配置中列出多个 sources、 sinks 和 channels。这些组件可以链接起来形成多个流：

~~~
# list the sources, sinks and channels for the agent
<Agent>.sources = <Source1> <Source2>
<Agent>.sinks = <Sink1> <Sink2>
<Agent>.channels = <Channel1> <Channel2>
~~~

然后，您可以将 sources 和 sinks 链接到它们相应的 channels ，来设置两个不同的流。
例如，如果您需要在 agent 中设置两个流，一个从 外部 avro 客户端 到 外部 HDFS，另一个从 tail 输出到 avro
sink，那么这里有一个配置来完成此操作：

~~~
# list the sources, sinks and channels in the agent
agent_foo.sources = avro-AppSrv-source1 exec-tail-source2
agent_foo.sinks = hdfs-Cluster1-sink1 avro-forward-sink2
agent_foo.channels = mem-channel-1 file-channel-2

# flow #1 configuration
agent_foo.sources.avro-AppSrv-source1.channels = mem-channel-1
agent_foo.sinks.hdfs-Cluster1-sink1.channel = mem-channel-1

# flow #2 configuration
agent_foo.sources.exec-tail-source2.channels = file-channel-2
agent_foo.sinks.avro-forward-sink2.channel = file-channel-2
~~~

## 配置 多 agent 流

要设置多层流，您需要在 `第一跳` 中有一个 avro/thrift sink 指向 `下一跳` 中的 avro/thrift source。
这将使 `第一个 Flume agent` 将事件转发给 `下一个 Flume agent`。

例如，如果您使用 avro 客户端 定期向 本地 Flume agent 发送文件(每个事件一个文件)，那么该 本地 agent 可以将其转发给
另一个已挂载该文件进行存储的 agent。

![](images/UserGuide_image03.png)

Weblog agent config:

~~~
# list sources, sinks and channels in the agent
agent_foo.sources = avro-AppSrv-source
agent_foo.sinks = avro-forward-sink
agent_foo.channels = file-channel

# define the flow
agent_foo.sources.avro-AppSrv-source.channels = file-channel
agent_foo.sinks.avro-forward-sink.channel = file-channel

# avro sink properties
agent_foo.sinks.avro-forward-sink.type = avro
agent_foo.sinks.avro-forward-sink.hostname = 10.1.1.100
agent_foo.sinks.avro-forward-sink.port = 10000

# configure other pieces
#...
~~~

HDFS agent config:

~~~
# list sources, sinks and channels in the agent
agent_foo.sources = avro-collection-source
agent_foo.sinks = hdfs-sink
agent_foo.channels = mem-channel

# define the flow
agent_foo.sources.avro-collection-source.channels = mem-channel
agent_foo.sinks.hdfs-sink.channel = mem-channel

# avro source properties
agent_foo.sources.avro-collection-source.type = avro
agent_foo.sources.avro-collection-source.bind = 10.1.1.100
agent_foo.sources.avro-collection-source.port = 10000

# configure other pieces
#...
~~~

这里我们将来自 weblog agent 的 avro-forward-sink 链接到 hdfs agent 的 avro-collection-source。
这将使来自外部应用服务器源的事件最终存储在 HDFS 中。

## 扇出流（Fan out flow）

![](images/UserGuide_image01.png)

如前一节所讨论的，Flume支持将流从一个 source 分散到多个 channel。
Fan out 有 `复制（replicating）` 和 `复用（multiplexing）` 两种模式。 在复制流中，事件被发送到所有配置的 channels。
在多路复用的情况下，事件仅被发送到`符合条件的 channels 子集`。要将流扇出，需要为 source 指定 `channels 列表` 和 `扇开策略`。
这是通过添加一个可以 复制 或 多路复用 的 `channel 选择器` 来实现的。如果是多路复用器，则进一步指定选择规则。
如果您没有指定选择器，那么默认情况下它是复制的：

~~~
# List the sources, sinks and channels for the agent
<Agent>.sources = <Source1>
<Agent>.sinks = <Sink1> <Sink2>
<Agent>.channels = <Channel1> <Channel2>

# set list of channels for source (separated by space)
<Agent>.sources.<Source1>.channels = <Channel1> <Channel2>

# set channel for sinks
<Agent>.sinks.<Sink1>.channel = <Channel1>
<Agent>.sinks.<Sink2>.channel = <Channel2>

<Agent>.sources.<Source1>.selector.type = replicating
~~~

多路选择有一组进一步的属性来分流。这需要指定事件属性到 `channel 集` 的映射。selector 检查事件头中的每个配置属性。
如果属性与指定的值匹配，则将该事件发送到`映射该值的所有 channels`。如果没有匹配，则将事件发送到配置为默认的 `channel 集`：

~~~
# Mapping for multiplexing selector
<Agent>.sources.<Source1>.selector.type = multiplexing
<Agent>.sources.<Source1>.selector.header = <someHeader>
<Agent>.sources.<Source1>.selector.mapping.<Value1> = <Channel1>
<Agent>.sources.<Source1>.selector.mapping.<Value2> = <Channel1> <Channel2>
<Agent>.sources.<Source1>.selector.mapping.<Value3> = <Channel2>
#...

<Agent>.sources.<Source1>.selector.default = <Channel2>
~~~

映射允许每个值的 channels 出现重叠。

下面的示例有一个多路复用到两条路径的流。名为 agent_foo 的 agent 具有单个 avro source 和 链接到两个 sinks 的两个
channels ：

~~~
# list the sources, sinks and channels in the agent
agent_foo.sources = avro-AppSrv-source1
agent_foo.sinks = hdfs-Cluster1-sink1 avro-forward-sink2
agent_foo.channels = mem-channel-1 file-channel-2

# set channels for source
agent_foo.sources.avro-AppSrv-source1.channels = mem-channel-1 file-channel-2

# set channel for sinks
agent_foo.sinks.hdfs-Cluster1-sink1.channel = mem-channel-1
agent_foo.sinks.avro-forward-sink2.channel = file-channel-2

# channel selector configuration
agent_foo.sources.avro-AppSrv-source1.selector.type = multiplexing
agent_foo.sources.avro-AppSrv-source1.selector.header = State
agent_foo.sources.avro-AppSrv-source1.selector.mapping.CA = mem-channel-1
agent_foo.sources.avro-AppSrv-source1.selector.mapping.AZ = file-channel-2
agent_foo.sources.avro-AppSrv-source1.selector.mapping.NY = mem-channel-1 file-channel-2
agent_foo.sources.avro-AppSrv-source1.selector.default = mem-channel-1
~~~

选择器检查名为State的标头。如果值是CA，那么它被发送到 mem-channel-1，如果是AZ，那么它被发送到 file-channel-2，如果是NY，那么两者都发送。
如果没有设置State报头，或者State报头与这三个中的任何一个都不匹配，则转到指定为默认值的 mem-channel-1。

选择器还支持可选通道。要为标头指定可选通道，可选的配置参数可按以下方式使用：

~~~
# channel selector configuration
agent_foo.sources.avro-AppSrv-source1.selector.type = multiplexing
agent_foo.sources.avro-AppSrv-source1.selector.header = State
agent_foo.sources.avro-AppSrv-source1.selector.mapping.CA = mem-channel-1
agent_foo.sources.avro-AppSrv-source1.selector.mapping.AZ = file-channel-2
agent_foo.sources.avro-AppSrv-source1.selector.mapping.NY = mem-channel-1 file-channel-2
agent_foo.sources.avro-AppSrv-source1.selector.optional.CA = mem-channel-1 file-channel-2
agent_foo.sources.avro-AppSrv-source1.selector.mapping.AZ = file-channel-2
agent_foo.sources.avro-AppSrv-source1.selector.default = mem-channel-1
~~~

选择器将首先尝试写入 `必需通道`，如果这些通道中`只要有一个`未能成功消费事件，则将使事务失败。在`所有通道`上重新尝试事务。
一旦所有 `必需通道` 都消费了事件，那么选择器将尝试写入 `可选通道`。任何可选通道使用事件失败都将被`忽略`，不会重试。

如果在特定 header 的 `可选通道` 和 `必需通道` 之间存在 `重叠`，则认为该通道是 `必需的`
，并且通道中的故障将导致重新尝试 `整个必需通道集`。
例如，在上面的示例中，对于 header `CA`， mem-channel-1 被认为是 `必需通道`（尽管它被标记为 `必需通道` 和 `可选通道`）
，并且向该通道的写入失败 将导致 在选择器配置的 `所有通道` 上重试该事件。

请注意，如果 header 没有任何 `必需通道`，则事件将被写入 `默认通道`，并将尝试写入该 header 的 `可选通道`。
如果没有 `默认通道`，也没有 `必需通道`，则选择器将尝试将事件写入 `可选通道`。在这种情况下，任何失败都将被`忽略`。

## Source 和 Sink 批大小以及 channel 事务容量

Source 和 Sink 可以通过 `batch size` 参数，来设置一个批处理过程中处理的`最大事件数`。
这会在`channel 事务`中设置一个上限，这个上限被称作`事务容量`。`batch size`必须小于通道的`事务容量`。
有一个显式检查来防止不兼容的设置。每当读取配置时，都会进行此检查。

