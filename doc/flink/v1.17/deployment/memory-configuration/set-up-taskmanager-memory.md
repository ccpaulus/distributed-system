# 配置 TaskManager 内存

Flink 的 TaskManager 负责执行用户代码。 根据实际需求为 TaskManager 配置内存将有助于减少 Flink 的资源占用，增强作业运行的稳定性。

本文接下来介绍的内存配置方法适用于 1.10 及以上版本。 Flink 在 1.10
版本中对内存配置部分进行了较大幅度的改动，从早期版本升级的用户请参考[升级指南]()。

提示 本篇内存配置文档<span style="color:orange; ">仅针对 TaskManager！</span> 与 [JobManager]() 相比，TaskManager
具有相似但更加复杂的内存模型。

## 配置总内存

Flink JVM 进程的*进程总内存（Total Process Memory）*包含了由 Flink 应用使用的内存（Flink 总内存）以及由运行 Flink 的 JVM
使用的内存。 其中，*Flink 总内存（Total Flink Memory）*包括 JVM 堆内存（Heap Memory）、*托管内存（Managed Memory）*
以及其他直接内存（Direct Memory）或本地内存（Native Memory）。

![](images/simple_mem_model.svg)

如果你是在本地运行 Flink（例如在 IDE 中）而非创建一个集群，那么本文介绍的配置并非所有都是适用的，详情请参考[本地执行]()。

其他情况下，配置 Flink 内存最简单的方法就是[配置总内存]()。 此外，Flink 也支持[更细粒度的内存配置方式]()。

Flink 会根据默认值或其他配置参数自动调整剩余内存部分的大小。 接下来的章节将介绍关于各内存部分的更多细节。

## 配置堆内存和托管内存

如[配置总内存]()中所述，另一种配置 Flink 内存的方式是同时设置[任务堆内存]()和[托管内存]()。 通过这种方式，用户可以更好地掌控用于
Flink 任务的 JVM 堆内存及 Flink 的[托管内存]()大小。

Flink 会根据默认值或其他配置参数自动调整剩余内存部分的大小。 关于各内存部分的更多细节，请参考[相关文档]()。

提示 如果已经明确设置了任务堆内存和托管内存，建议不要再设置进程总内存或 Flink 总内存，否则可能会造成内存配置冲突。

### 任务（算子）堆内存

如果希望确保指定大小的 JVM 堆内存给用户代码使用，可以明确指定任务堆内存（[taskmanager.memory.task.heap.size]()）。
指定的内存将被包含在总的 JVM 堆空间中，专门用于 Flink 算子及用户代码的执行。

### 托管内存

托管内存是由 Flink 负责分配和管理的本地（堆外）内存。 以下场景需要使用托管内存：

* 流处理作业中用于 [RocksDB State Backend]()。
* 流处理和批处理作业中用于排序、哈希表及缓存中间结果。
* 流处理和批处理作业中用于[在 Python 进程中执行用户自定义函数]()。

可以通过以下两种范式指定托管内存的大小：

* 通过 [taskmanager.memory.managed.size]() 明确指定其大小。
* 通过 [taskmanager.memory.managed.fraction]() 指定在Flink 总内存中的占比。

当同时指定二者时，会优先采用指定的大小（Size）。 若二者均未指定，会根据[默认占比]()进行计算。

请同时参考[如何配置 State Backend 内存]()以及[如何配置批处理作业内存]()。

#### 消费者权重

对于包含不同种类的托管内存消费者的作业，可以进一步控制托管内存如何在消费者之间分配。
通过 [taskmanager.memory.managed.consumer-weights]() 可以为每一种类型的消费者指定一个权重，Flink 会按照权重的比例进行内存分配。
目前支持的消费者类型包括：

* OPERATOR: 用于内置算法。
* STATE_BACKEND: 用于流处理中的 RocksDB State Backend。
* PYTHON：用户 Python 进程。

例如，一个流处理作业同时使用到了 RocksDB State Backend 和 Python UDF，消费者权重设置为 STATE_BACKEND:70,PYTHON:30，那么
Flink 会将 70% 的托管内存用于 RocksDB State Backend，30% 留给 Python 进程。

提示 只有作业中包含某种类型的消费者时，Flink 才会为该类型分配托管内存。 例如，一个流处理作业使用 Heap State Backend 和
Python UDF，消费者权重设置为 STATE_BACKEND:70,PYTHON:30，那么 Flink 会将全部托管内存用于 Python 进程，因为 Heap State
Backend 不使用托管内存。

提示 对于未出现在消费者权重中的类型，Flink 将不会为其分配托管内存。 如果缺失的类型是作业运行所必须的，则会引发内存分配失败。
默认情况下，消费者权重中包含了所有可能的消费者类型。 上述问题仅可能出现在用户显式地配置了消费者权重的情况下。

## 配置堆外内存（直接内存或本地内存）

用户代码中分配的堆外内存被归为任务堆外内存（Task Off-heap Memory），可以通过 `taskmanager.memory.task.off-heap.size` 指定。

提示 你也可以调整[框架堆外内存（Framework Off-heap Memory）]()。 这是一个进阶配置，建议仅在确定 Flink 框架需要更多的内存时调整该配置。

Flink 将框架堆外内存和任务堆外内存都计算在 JVM 的直接内存限制中，请参考 [JVM 参数]()。

提示 本地内存（非直接内存）也可以被归在框架堆外内存或任务堆外内存中，在这种情况下 JVM 的直接内存限制可能会高于实际需求。

提示 网络内存（Network Memory）同样被计算在 JVM 直接内存中。 Flink 会负责管理网络内存，保证其实际用量不会超过配置大小。
因此，调整网络内存的大小不会对其他堆外内存有实质上的影响。

请参考[内存模型详解]()。

内存模型详解 #

![](images/detailed-mem-model.svg)

如上图所示，下表中列出了 Flink TaskManager 内存模型的所有组成部分，以及影响其大小的相关配置参数。

| **组成部分**                              | **配置参数**                                                                                                                             | **描述**                                                                           |
|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| [框架堆内存（Framework Heap Memory）]()      | [taskmanager.memory.framework.heap.size]()                                                                                           | 用于 Flink 框架的 JVM 堆内存（进阶配置）。                                                      |
| [任务堆内存（Task Heap Memory）]()           | [taskmanager.memory.task.heap.size]()                                                                                                | 用于 Flink 应用的算子及用户代码的 JVM 堆内存。                                                    |
| [托管内存（Managed memory）]()              | [taskmanager.memory.managed.size]()<br/>[taskmanager.memory.managed.fraction]()                                                      | 由 Flink 管理的用于排序、哈希表、缓存中间结果及 RocksDB State Backend 的本地内存。                         |
| [框架堆外内存（Framework Off-heap Memory）]() | [taskmanager.memory.framework.off-heap.size]()                                                                                       | 用于 Flink 框架的[堆外内存（直接内存或本地内存）]()（进阶配置）。                                           |
| [任务堆外内存（Task Off-heap Memory）]()      | [taskmanager.memory.task.off-heap.size]()                                                                                            | 用于 Flink 应用的算子及用户代码的[堆外内存（直接内存或本地内存）]()。                                         |
| 网络内存（Network Memory）                  | [taskmanager.memory.network.min]()<br/>[taskmanager.memory.network.max]()<br/>[taskmanager.memory.network.fraction]()                | 用于任务之间数据传输的直接内存（例如网络传输缓冲）。该内存部分为基于 [Flink 总内存]()的[受限的等比内存部分]()。这块内存被用于分配[网络缓冲]() |
| [JVM Metaspace]()                     | [taskmanager.memory.jvm-metaspace.size]()                                                                                            | Flink JVM 进程的 Metaspace。                                                         |
| JVM 开销                                | [taskmanager.memory.jvm-overhead.min]()<br/>[taskmanager.memory.jvm-overhead.max]()<br/>[taskmanager.memory.jvm-overhead.fraction]() | 用于其他 JVM 开销的本地内存，例如栈空间、垃圾回收空间等。该内存部分为基于[进程总内存]()的[受限的等比内存部分]()。                  |

我们可以看到，有些内存部分的大小可以直接通过一个配置参数进行设置，有些则需要根据多个参数进行调整。

## 框架内存

通常情况下，不建议对框架堆内存和框架堆外内存进行调整。 除非你非常肯定 Flink 的内部数据结构及操作需要更多的内存。
这可能与具体的部署环境及作业结构有关，例如非常高的并发度。 此外，Flink 的部分依赖（例如 Hadoop）在某些特定的情况下也可能会需要更多的直接内存或本地内存。

提示 不管是堆内存还是堆外内存，Flink 中的框架内存和任务内存之间目前是没有隔离的。 对框架和任务内存的区分，主要是为了在后续版本中做进一步优化。

## 本地执行

如果你是将 Flink 作为一个单独的 Java 程序运行在你的电脑本地而非创建一个集群（例如在 IDE 中），那么只有下列配置会生效，其他配置参数则不会起到任何效果：

| **组成部分** | **配置参数**                                                                  | **本地执行时的默认值** |
|----------|---------------------------------------------------------------------------|---------------|
| 任务堆内存    | [taskmanager.memory.task.heap.size]()                                     | 无穷大           |
| 任务堆外内存   | [taskmanager.memory.task.off-heap.size]()	                                | 无穷大           |
| 托管内存     | [taskmanager.memory.managed.size]()                                       | 128MB         |
| 网络内存     | [taskmanager.memory.network.min]()<br/>[taskmanager.memory.network.max]() | 64MB          |

本地执行模式下，上面列出的所有内存部分均可以但不是必须进行配置。 如果未配置，则会采用默认值。 其中，[任务堆内存]()
和任务堆外内存的默认值无穷大（Long.MAX_VALUE 字节），以及[托管内存]()的默认值 128MB 均只针对本地执行模式。

提示 这种情况下，任务堆内存的大小与实际的堆空间大小无关。 该配置参数可能与后续版本中的进一步优化相关。 本地执行模式下，JVM
堆空间的实际大小不受 Flink 掌控，而是取决于本地执行进程是如何启动的。 如果希望控制 JVM 的堆空间大小，可以在启动进程时明确地指定相关的
JVM 参数，即 `-Xmx` 和 `-Xms`。

