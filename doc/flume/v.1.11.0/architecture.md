# 架构

## 数据流模型（Data flow model）

`Flume event`被定义为具有`字节负载`和`一组可选字符串属性`的`数据流单元`。
`Flume agent`是一个(JVM)进程，它承载着`事件（event）`从`外部源`流向下一个`目的地（hop）`的组件。

![](images/UserGuide_image00.png)

Flume source 消费由 `外部源(如web服务器)` 传递给它的事件。外部源以 `目标 Flume source` 可识别的格式向 Flume 发送事件。

例如，Avro Flume source 可从以下来源接收 Avro 事件：

1. Avro 客户端
2. 流程中，通过 Avro sink 发送事件的其他 Flume agents

类似的，Thrift Flume Source 可从以下来源接收事件：

1. Thrift Sink
2. Flume Thrift Rpc Client
3. 使用 `Flume Thrift 协议` 生成的 `任何语言编写的` Thrift clients。

当 Flume source 接收到事件时，它将其存储到一个或多个 channel 中。channel 是一个被动存储，channel 会保存事件，直到事件被
Flume sink 消费。

例如：file channel，它由本地文件系统支持。sink 从 channel 中删除事件，并将其放入像 HDFS 这样的外部存储库(通过 Flume HDFS
sink)，或者将其转发到流程中 `下一个 Flume agent(下一跳)` 的 Flume source 。

给定 agent 中的 source 和 sink 对 channel 中`暂存事件`的操作是`异步的`。

## 复杂流程（Complex flows）

Flume 允许用户构建`多跳流（multi-hop flows）`，其中事件在到达最终目的地之前经过多个 agent。它还允许 fan-in 和 fan-out
流、上下文路由和失败跳点的备份路由(故障转移)。

## 可靠性（Reliability）

事件暂存在每个 agent 上的 channel 中。然后将事件传递到流中的下一个 agent 或终端存储库(如HDFS)。
事件只有在存储到 `下一个 agent 的 channel` 或 `终端存储库` 之后才会从 channel 中删除。
Flume 中的`单跳消息传递语义`就是通过这种方式来提供 流的`端到端可靠性`。

Flume 使用 `事务` 来保证事件的可靠传递。
Flume 使用 `两个独立的事务` 分别负责 `从 source 到 channel`，以及` 从 channel 到 sink` 的事件传递。
这确保了`事件集`在流中可靠地从一个点传递到另一个点。在`多跳流`的情况下，`前一跳的 sink` 和 `下一跳的 source`
都运行事务，以确保数据安全地存储在 `下一跳的 channel` 中。

## 可恢复性（Recoverability）

事件在 channel 中暂存，channel 管理故障恢复。Flume 支持`基于本地文件系统`的`持久化 file channel`
。同时还有一个 `memory channel`，它只是将事件存储在内存队列中，这样更快，但是当 agent 进程死亡时，仍然留在 memory channel
中的任何事件都无法恢复。

Flume 的 KafkaChannel 使用 Apache Kafka 来暂存事件。使用 `replicated Kafka topic` 作为 channel 避免磁盘故障时出现事件丢失。

