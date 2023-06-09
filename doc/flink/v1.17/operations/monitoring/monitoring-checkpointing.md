# 监控 Checkpoint

## 概览（Overview）

Flink 的 Web 界面提供了选项卡/标签（tab）来监视作业的 checkpoint 信息。作业终止后，这些统计信息仍然可用。有四个不同的选项卡可显示有关
checkpoint 的信息：概览（Overview），历史记录（History），摘要信息（Summary）和配置信息（Configuration）。以下各节将依次介绍这些内容。

## 监控（Monitoring）

### 概览（Overview）选项卡

概览选项卡列出了以下统计信息。请注意，这些统计信息在 JobManager 丢失时无法保存，如果 JobManager 发生故障转移，这些统计信息将重置。

* **Checkpoint Counts**
    * Triggered：自作业开始以来触发的 checkpoint 总数。
    * In Progress：当前正在进行的 checkpoint 数量。
    * Completed：自作业开始以来成功完成的 checkpoint 总数。
    * Failed：自作业开始以来失败的 checkpoint 总数。
    * Restored：自作业开始以来进行的恢复操作的次数。这还表示自 提交以来已重新启动多少次。请注意，带有 savepoint
      的初始提交也算作一次恢复，如果 JobManager 在此操作过程中丢失，则该统计将重新计数。
* **Latest Completed Checkpoint**：最新（最近）成功完成的 checkpoint。点击 More details 可以得到 subtask 级别的详细统计信息。
* **Latest Failed Checkpoint**：最新失败的 checkpoint。点击 More details 可以得到 subtask 级别的详细统计信息。
* **Latest Savepoint**：最新触发的 savepoint 及其外部路径。点击 More details 可以得到 subtask 级别的详细统计信息。
* **Latest Restore**：有两种类型的恢复操作。
    * Restore from Checkpoint：从 checkpoint 恢复。
    * Restore from Savepoint：从 savepoint 恢复。

### 历史记录（History）选项卡

Checkpoint 历史记录保存有关最近触发的 checkpoint 的统计信息，包括当前正在进行的 checkpoint。

注意，对于失败的 checkpoint，指标会尽最大努力进行更新，但是可能不准确。

![](images/checkpoint_monitoring-history.png)

* **ID**：已触发 checkpoint 的 ID。每个 checkpoint 的 ID 都会递增，从 1 开始。
* **Status**：Checkpoint 的当前状态，可以是正在进行（In Progress）、已完成（Completed） 或失败（Failed））。如果触发的检查点是一个保存点，你将看到一个
  符号。
* **Acknowledged**：已确认完成的子任务数量与总任务数量。
* **Trigger Time**：在 JobManager 上发起 checkpoint 的时间。
* **Latest Acknowledgement**：JobManager 接收到任何 subtask 的最新确认的时间（如果尚未收到确认，则不适用）。
* **End to End Duration**：从触发时间戳到最后一次确认的持续时间（如果还没有收到确认，则不适用）。完整 checkpoint 的端到端持续时间由确认
  checkpoint 的最后一个 subtask 确定。这个时间通常大于单个 subtask 实际 checkpoint state 所需的时间。
* **Checkpointed Data Size**: 在此次checkpoint的sync以及async阶段中持久化的数据量。如果启用了增量
  checkpoint或者changelog，则此值可能会与全量checkpoint数据量产生区别。
* **Full Checkpoint Data Size**: 所有已确认的 subtask 的 checkpoint 的全量数据大小。
* **Processed (persisted) in-flight data**：在 checkpoint 对齐期间（从接收第一个和最后一个 checkpoint barrier 之间的时间）所有已确认的
  subtask 处理/持久化 的大约字节数。如果启用了 unaligned checkpoint，持久化的字节数可能会大于0。

对于 subtask，有两个更详细的统计信息可用。

![](images/checkpoint_monitoring-history-subtasks.png)

* **Sync Duration**：Checkpoint 同步部分的持续时间。这包括 operator 的快照状态，并阻塞 subtask 上的所有其他活动（处理记录、触发计时器等）。
* **Async Duration**：Checkpoint 的异步部分的持续时间。这包括将 checkpoint 写入设置的文件系统所需的时间。对于 unaligned
  checkpoint，这还包括 subtask 必须等待最后一个 checkpoint barrier 到达的时间（checkpoint alignment 持续时间）以及持久化数据所需的时间。
* **Alignment Duration**：处理第一个和最后一个 checkpoint barrier 之间的时间。对于 checkpoint alignment 机制的
  checkpoint，在 checkpoint alignment 过程中，已经接收到 checkpoint barrier 的 channel 将阻塞并停止处理后续的数据。
* **Start Delay**：从 checkpoint barrier 创建开始到 subtask 收到第一个 checkpoint barrier 所用的时间。
* **Unaligned Checkpoint**：Checkpoint 完成的时候是否是一个 unaligned checkpoint。在 alignment 超时的时候 aligned
  checkpoint 可以自动切换成 unaligned checkpoint。

#### 历史记录数量配置

你可以通过以下配置键配置历史记录所保存的最近检查点的数量。默认值为 10。

~~~
# 保存最近 checkpoint 的个数
web.checkpoints.history: 15
~~~

### 摘要信息（Summary）选项卡

摘要计算了所有已完成 checkpoint 的端到端持续时间、增量/全量Checkpoint 数据大小和 checkpoint alignment 期间缓冲的字节数的简单
min/average/maximum 统计信息（有关这些内容的详细信息，请参见 [History]()）。

![](images/checkpoint_monitoring-summary.png)

请注意，这些统计信息不会在 JobManager 丢失后无法保存，如果 JobManager 故障转移，这些统计信息将重新计数。

### 配置信息（Configuration）选项卡

该配置选项卡列出了你指定的配置（streaming configuration）：

* **Checkpointing Mode**：恰好一次（Exactly Once）或者至少一次（At least Once）。
* **Interval**：配置的 checkpoint 触发间隔。在此间隔内触发 checkpoint。
* **Timeout**：超时之后，JobManager 取消 checkpoint 并触发新的 checkpoint。
* **Minimum Pause Between Checkpoints**：Checkpoint 之间所需的最小暂停时间。Checkpoint 成功完成后，我们至少要等这段时间再触发下一个，这可能会延迟正常的间隔。
* **Maximum Concurrent Checkpoints**：可以同时进行的最大 checkpoint 个数。
* **Persist Checkpoints Externally**：启用或禁用持久化 checkpoint 到外部系统。如果启用，还会列出外部化 checkpoint
  的清理配置（取消时删除或保留）。

## Checkpoint 详细信息

当你点击某个 checkpoint 的 More details 链接时，你将获得其所有 operator 的 Minimum/Average/Maximum 摘要信息，以及每个
subtask 单独的详细量化信息。

![](images/checkpoint_monitoring-details.png)

### 每个 Operator 的摘要信息

![](images/checkpoint_monitoring-details_summary.png)

### 所有 Subtask 的统计信息

![](images/checkpoint_monitoring-details_subtasks.png)

