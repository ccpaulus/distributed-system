# 常见问题

## IllegalConfigurationException

如果遇到从 TaskExecutorProcessUtils 或 JobManagerProcessUtils 抛出的 IllegalConfigurationException
异常，这通常说明您的配置参数中存在无效值（例如内存大小为负数、占比大于 1 等）或者配置冲突。
请根据异常信息，确认出错的内存部分的相关文档及[配置信息]()。

## OutOfMemoryError: Java heap space

该异常说明 JVM 的堆空间过小。 可以通过增大[总内存]()、TaskManager 的[任务堆内存]()、JobManager 的 [JVM 堆内存]()等方法来增大
JVM 堆空间。

提示 也可以增大 TaskManager 的[框架堆内存]()。 这是一个进阶配置，只有在确认是 Flink 框架自身需要更多内存时才应该去调整。

## OutOfMemoryError: Direct buffer memory

该异常通常说明 JVM 的直接内存限制过小，或者存在直接内存泄漏（Direct Memory Leak）。 请确认用户代码及外部依赖中是否使用了 JVM
直接内存，以及如果使用了直接内存，是否配置了足够的内存空间。 可以通过调整堆外内存来增大直接内存限制。
有关堆外内存的配置方法，请参考 [TaskManager]()、[JobManager]() 以及 [JVM 参数]()的相关文档。

## OutOfMemoryError: Metaspace

该异常说明 [JVM Metaspace 限制]()过小。 可以尝试调整 [TaskManager]()、[JobManager]() 的 JVM Metaspace。

## IOException: Insufficient number of network buffers

该异常仅与 TaskManager 相关。

该异常通常说明[网络内存]()过小。 可以通过调整以下配置参数增大网络内存：

* [taskmanager.memory.network.min]()
* [taskmanager.memory.network.max]()
* [taskmanager.memory.network.fraction]()

## 容器（Container）内存超用

如果 Flink 容器尝试分配超过其申请大小的内存（Yarn 或 Kubernetes），这通常说明 Flink 没有预留出足够的本地内存。
可以通过外部监控系统或者容器被部署环境杀掉时的错误信息判断是否存在容器内存超用。

对于 JobManager 进程，你还可以尝试启用 JVM 直接内存限制（[jobmanager.memory.enable-jvm-direct-memory-limit]()），以排除 JVM
直接内存泄漏的可能性。

If [RocksDBStateBackend]() is used：

and memory controlling is disabled: You can try to increase the TaskManager’s [managed memory]().
and memory controlling is enabled and non-heap memory increases during savepoint or full checkpoints: This may happen
due to the glibc memory allocator (see [glibc bug]()). You can try to add the [environment variable]()
MALLOC_ARENA_MAX=1 for TaskManagers.
此外，还可以尝试增大 [JVM 开销]()。

请参考如何配置容器内存。

