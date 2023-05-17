# 配置 Flink 进程的内存

Apache Flink 基于 JVM 的高效处理能力，依赖于其对各组件内存用量的细致掌控。 考虑到用户在 Flink
上运行的应用的多样性，尽管社区已经努力为所有配置项提供合理的默认值，仍无法满足所有情况下的需求。 为了给用户生产提供最大化的价值，
Flink 允许用户在整体上以及细粒度上对集群的内存分配进行调整。为了优化内存需求，参考[网络内存调优指南]()。

本文接下来介绍的内存配置方法适用于 1.10 及以上版本的 TaskManager 进程和 1.11 及以上版本的 JobManager 进程。 Flink 在 1.10
和 1.11 版本中对内存配置部分进行了较大幅度的改动，从早期版本升级的用户请参考[升级指南]()。

## 配置总内存

Flink JVM 进程的`进程总内存（Total Process Memory）`包含了由 Flink 应用使用的内存（`Flink 总内存`）以及由运行 Flink 的 JVM
使用的内存。 `Flink 总内存（Total Flink Memory）`包括 `JVM 堆内存（Heap Memory）`和`堆外内存（Off-Heap Memory）`。
其中堆外内存包括`直接内存（Direct Memory）`和`本地内存（Native Memory）`。

![](images/process_mem_model.svg)

配置 Flink 进程内存最简单的方法是指定以下两个配置项中的任意一个：

| **配置项**   | **TaskManager 配置参数**                | **JobManager 配置参数**                |
|-----------|-------------------------------------|------------------------------------|
| Flink 总内存 | [taskmanager.memory.flink.size]()   | [jobmanager.memory.flink.size]()   |
| 进程总内存     | [taskmanager.memory.process.size]() | [jobmanager.memory.process.size]() |

提示 关于本地执行，请分别参考 [TaskManager]() 和 [JobManager]() 的相关文档。

Flink 会根据默认值或其他配置参数自动调整剩余内存部分的大小。 关于各内存部分的更多细节，请分别参考 [TaskManager]()
和 [JobManager]() 的相关文档。

对于[独立部署模式（Standalone Deployment）]()，如果你希望指定由 Flink 应用本身使用的内存大小，最好选择配置 Flink 总内存。
Flink 总内存会进一步划分为 JVM 堆内存和堆外内存。 更多详情请参考[如何为独立部署模式配置内存]()。

通过配置进程总内存可以指定由 Flink JVM 进程使用的总内存大小。 对于容器化部署模式（Containerized
Deployment），这相当于申请的容器（Container）大小，详情请参考[如何配置容器内存]()（[Kubernetes]() 或 [Yarn]()）。

此外，还可以通过设置 Flink 总内存的特定内部组成部分的方式来进行内存配置。 不同进程需要设置的内存组成部分是不一样的。
详情请分别参考 [TaskManager]() 和 [JobManager]() 的相关文档。

提示 以上三种方式中，用户需要至少选择其中一种进行配置（本地运行除外），否则 Flink 将无法启动。
这意味着，用户需要从以下无默认值的配置参数（或参数组合）中选择一个给出明确的配置：

TaskManager:      JobManager:  
taskmanager.memory.flink.size jobmanager.memory.flink.size
taskmanager.memory.process.size jobmanager.memory.process.size
taskmanager.memory.task.heap.size 和
taskmanager.memory.managed.size jobmanager.memory.heap.size

| **TaskManager**                                                         | **JobManager**                     |
|-------------------------------------------------------------------------|------------------------------------|
| [taskmanager.memory.flink.size]()                                       | [jobmanager.memory.flink.size]()   |
| [taskmanager.memory.process.size]()                                     | [jobmanager.memory.process.size]() |
| [taskmanager.memory.task.heap.size 和 taskmanager.memory.managed.size]() | [jobmanager.memory.heap.size]()    |

提示 不建议同时设置进程总内存和 Flink 总内存。 这可能会造成内存配置冲突，从而导致部署失败。 额外配置其他内存部分时，同样需要注意可能产生的配置冲突。

## JVM 参数

Flink 进程启动时，会根据配置的和自动推导出的各内存部分大小，显式地设置以下 JVM 参数：

JVM 参数 TaskManager 取值 JobManager 取值  
-Xmx 和 -Xms 框架堆内存 + 任务堆内存 JVM 堆内存 (*)
-XX:MaxDirectMemorySize
（TaskManager 始终设置，JobManager 见注释） 框架堆外内存 + 任务堆外内存(**) + 网络内存 堆外内存 (**) (***)
-XX:MaxMetaspaceSize JVM Metaspace JVM Metaspace
(*) 请记住，根据所使用的 GC 算法，你可能无法使用到全部堆内存。一些 GC 算法会为它们自身分配一定量的堆内存。这会导致堆的指标返回一个不同的最大值。

(**) 请注意，堆外内存也包括了用户代码使用的本地内存（非直接内存）。

(***) 只有在 jobmanager.memory.enable-jvm-direct-memory-limit 设置为 true 时，JobManager 才会设置 JVM 直接内存限制。

| **JVM 参数**                                                                                            | **TaskManager 取值**         | **JobManager 取值** |
|-------------------------------------------------------------------------------------------------------|----------------------------|-------------------|
| -Xmx 和 -Xms                                                                                           | 框架堆内存 + 任务堆内存              | JVM 堆内存 (*)       |
| -XX:MaxDirectMemorySize（TaskManager 始终设置，JobManager 见注释）                                              | 框架堆外内存 + 任务堆外内存(**) + 网络内存 | 堆外内存 (**) (***)   |
| -XX:MaxMetaspaceSize                                                                                  | JVM Metaspace              | JVM Metaspace     |
| (*) 请记住，根据所使用的 GC 算法，你可能无法使用到全部堆内存。一些 GC 算法会为它们自身分配一定量的堆内存。这会导致[堆的指标]()返回一个不同的最大值。                    |                            |                   |
| (**) 请注意，堆外内存也包括了用户代码使用的本地内存（非直接内存）。                                                                  |                            |                   |
| (***) 只有在 [jobmanager.memory.enable-jvm-direct-memory-limit]() 设置为 true 时，JobManager 才会设置 JVM 直接内存限制。 |                            |                   |

相关内存部分的配置方法，请同时参考 [TaskManager]() 和 [JobManager]() 的详细内存模型。

## 受限的等比内存部分

本节介绍下列内存部分的配置方法，它们都可以通过指定在总内存中所占比例的方式进行配置，同时受限于相应的的最大/最小值范围。

* JVM 开销：可以配置占用进程总内存的固定比例
* 网络内存：可以配置占用 Flink 总内存的固定比例（仅针对 TaskManager）

相关内存部分的配置方法，请同时参考 [TaskManager]() 和 [JobManager]() 的详细内存模型。

这些内存部分的大小必须在相应的最大值、最小值范围内，否则 Flink 将无法启动。 最大值、最小值具有默认值，也可以通过相应的配置参数进行设置。
例如，如果仅配置下列参数：

* 进程总内存 = 1000MB
* JVM 开销最小值 = 64MB
* JVM 开销最大值 = 128MB
* JVM 开销占比 = 0.1

那么 JVM 开销的实际大小将会是 1000MB x 0.1 = 100MB，在 64-128MB 的范围内。

如果将最大值、最小值设置成相同大小，那相当于明确指定了该内存部分的大小。

如果没有明确指定内存部分的大小，Flink 会根据总内存和占比计算出该内存部分的大小。 计算得到的内存大小将受限于相应的最大值、最小值范围。
例如，如果仅配置下列参数：

* 进程总内存 = 1000MB
* JVM 开销最小值 = 128MB
* JVM 开销最大值 = 256MB
* JVM 开销占比 = 0.1

那么 JVM 开销的实际大小将会是 128MB，因为根据总内存和占比计算得到的内存大小 100MB 小于最小值。

如果配置了总内存和其他内存部分的大小，那么 Flink 也有可能会忽略给定的占比。 这种情况下，受限的等比内存部分的实际大小是总内存减去其他所有内存部分后剩余的部分。
这样推导得出的内存大小必须符合最大值、最小值范围，否则 Flink 将无法启动。 例如，如果仅配置下列参数：

* 进程总内存 = 1000MB
* 任务堆内存 = 100MB（或 JobManager 的 JVM 堆内存）
* JVM 开销最小值 = 64MB
* JVM 开销最大值 = 256MB
* JVM 开销占比 = 0.1

进程总内存中所有其他内存部分均有默认大小，包括 TaskManager 的托管内存默认占比或 JobManager 的默认堆外内存。 因此，JVM
开销的实际大小不是根据占比算出的大小（1000MB x 0.1 = 100MB），而是进程总内存中剩余的部分。 这个剩余部分的大小必须在 64-256MB
的范围内，否则将会启动失败。

