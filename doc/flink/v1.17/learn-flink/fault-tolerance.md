# 通过状态快照实现容错处理

## State Backends

由Flink管理的`keyed state`是一种分片的`key/value`存储，每个`keyed state`项的工作副本保存在`负责该key`的`taskmanager`
的`本地某个地方`。`Operator state`对于需要它的机器来说也是本地的。

Flink管理的`state`存储在`state backend`。有两种`state backend`实现可用：

* 一个基于`RocksDB`，一种内嵌的`key/value`存储，将工作`state`存储在磁盘上；
* 另一个基于`堆`的`state backend`，将其工作`state`保存在Java堆上的内存中。

| Name                        | Working State        | Snapshotting       |                                        |
|-----------------------------|----------------------|--------------------|----------------------------------------|
| EmbeddedRocksDBStateBackend | Local disk (tmp dir) | Full / Incremental | * 支持大于可用内存的状态 <br/> * 经验法则:比基于堆的后端慢10倍 |
| HashMapStateBackend         | JVM Heap             | Full               | * 快速，需要大堆 <br/> * 以GC为准                |

当处理保存在基于堆的`state backend`的状态时，访问和更新涉及在堆上读写对象。
但是对于保存在`EmbeddedRocksDBStateBackend`中的对象，访问和更新涉及`序列化`和`反序列化`，所以会有`更大的开销`。
但是`RocksDB`的`state`数量仅受本地磁盘大小的限制。
还要注意，只有`EmbeddedRocksDBStateBackend`能够执行`增量快照`，这对于具有`大量缓慢变化的state`的应用程序来说是一个显著的好处。

这两个`state backend`都能够执行异步快照，这意味着它们可以在不妨碍正在进行的流处理的情况下执行快照。

## Checkpoint Storage

Flink定期获取每个`operator`的所有`state`的持久快照，并将这些快照复制到更持久的地方，比如`分布式文件系统`。
如果发生故障，Flink 可以恢复应用程序的完整`state`，并恢复处理过程，就好像没有出现任何问题一样。

存储这些快照的位置是通过作业的`checkpoint storage`定义的。
`checkpoint storage`有两种可用的实现：

* 一种将其`state`的快照持久化到分布式文件系统；
* 另一种使用JobManager的堆。

| Name                        | State Backup        |                                                 |
|-----------------------------|---------------------|-------------------------------------------------|
| FileSystemCheckpointStorage | 分布式文件系统             | * 支持非常大的`state`大小 <br/> * 高度可靠 <br/> * 推荐用于生产部署 |
| JobManagerCheckpointStorage | JobManager JVM Heap | * 适用于小`state`(本地)的测试和实验                         |

## State Snapshots

### Definitions

* 快照（Snapshot）
  <br/>是 Flink 作业状态全局一致镜像的通用术语。快照包括指向每个数据源的指针（例如，到文件或 Kafka
  分区的偏移量）以及每个作业的有状态运算符的状态副本，该状态副本是处理了 sources 偏移位置之前所有的事件后而生成的状态。
* Checkpoint
  <br/>一种由 Flink `自动执行的快照`，其目的是`能够从故障中恢复`。Checkpoints 可以是`增量的`，并为快速恢复进行了优化。
* 外部化的 Checkpoint（Externalized Checkpoint）
  <br/> 通常 checkpoints 不会被用户操纵。Flink 只保留作业运行时的最近的 `n 个 checkpoints`（n
  可配置），并在作业取消时删除它们。但你可以将它们配置为保留，在这种情况下，你可以手动从中恢复。
* Savepoint
  <br/>由`用户`(或`API调用`)为某些操作目的`手动触发的快照`，比如有状态的`redeploy`或`upgrade`或`rescaling`操作。
  `savepoints`总是完整的，并且已针对操作灵活性进行了优化。

### How does State Snapshotting Work?

Flink 使用 [Chandy-Lamport algorithm]() 算法的一种变体，称为异步 barrier 快照（asynchronous barrier snapshotting）。

当`checkpoint coordinator`(`JobManager`的一部分)指示`TaskManager`开始`checkpoint`时，它会让所有`sources`
记录它们的`offsets`，并将编号了的`checkpoint barriers`插入到它们的流中。这些`barriers`流经`JobGraph`，指示每个`checkpoint`
前后的流部分。

![](images/fault-tolerance/stream_barriers.svg)

`Checkpoint n` 将包含每个 operator 的 state，这些 state 是对应的 operator 消费了严格在 `checkpoint barrier n`
之前的所有事件，并且不包含在此（`checkpoint barrier n`）后的任何事件后而生成的状态。

当 job graph 中的每个 operator 接收到 barriers 时，它就会记录下其状态。拥有两个输入流的 Operators（例如
CoProcessFunction）会执行 barrier 对齐（barrier alignment） 以便当前快照能够包含消费两个输入流 barrier 之前（但不超过）的所有
events 而产生的状态。

![](images/fault-tolerance/stream_aligning.svg)

Flink 的 state backends 利用`写时复制（copy-on-write）机制`允许当异步生成旧版本的`状态快照`
时，能够不受影响地继续流处理。只有当快照被持久保存后，这些旧版本的状态才会被当做`垃圾回收`。

### Exactly Once Guarantees

当流处理应用程序发生错误的时候，结果可能会产生丢失或者重复。Flink 根据你为应用程序和集群的配置，可以产生以下结果：

* Flink 不会从快照中进行恢复（at most once）
* 没有任何丢失，但是你可能会得到重复冗余的结果（at least once）
* 没有丢失或冗余重复（exactly once）

假设Flink通过`回退（rewinding）`和`重新发送（replaying）` source 数据流来从故障中恢复，当理想情况被描述为`exactly once`
时，并不意味着每个事件都将被恰好处理一次。相反，这意味着 每一个事件都会影响 Flink 管理的状态精确一次。

`Barrier` 只有在需要提供`精确一次的语义`保证时需要进行`对齐（Barrier alignment）`
。如果不需要这种语义，可以通过配置 `CheckpointingMode.AT_LEAST_ONCE` 关闭 Barrier 对齐来提高性能。

### Exactly Once End-to-end

要实现端到端的`exactly once`，以便来自`sources`的每个事件对`sinks`产生`精确一次`地影响，必须满足以下条件：

* 1.`sources`必须是可重复播放的；
* 2.`sinks`必须是事务性的(或幂等的)。

## 实践练习

[Flink Operations Playground]() 包括有关 [Observing Failure & Recovery]() 的部分。

## 延伸阅读

* [Stateful Stream Processing]()
* [State Backends]()
* [Data Sources 和 Sinks 的容错保证]()
* [开启和配置 Checkpointing]()
* [Checkpoints]()
* [Savepoints]()
* [大状态与 Checkpoint 调优]()
* [监控 Checkpoint]()
* [Task 故障恢复]()

