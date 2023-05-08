# Flink Architecture

Flink是一个分布式系统，需要有效地分配和管理计算资源才能执行流应用程序。
它集成了所有常见的集群资源管理器，如`Hadoop YARN`和`Kubernetes`，但也可以设置为作为一个独立的集群运行，甚至作为一个库。

## Flink集群剖析

Flink`运行时（runtime）`由两种类型的进程组成:一个`JobManager`和一个或多个`TaskManager`。

![](images/architecture/processes.svg)

`Client`不是运行时和程序执行的一部分，而是用于准备和发送`数据流程（dataflow）`到JobManager。
之后，`Client`可以断开连接(分离模式)，或者保持连接以接收进度报告(附加模式)。
`Client`可以通过 Java/Scala 程序触发执行，也可以通过命令行执行`./bin/flink run ....`。

`JobManager`和`TaskManagers`可以通过多种方式启动:
直接在机器上作为`独立集群（standalone cluster）`启动，在容器中启动，或者由YARN等资源框架管理。
`TaskManagers`会连接到`JobManager`，宣布自己可用，并被分配工作。

### JobManager

`JobManager`有许多与`协调Flink应用程序的分布式执行`相关的职责：它决定何时调度下一个任务(或一组任务)
，对完成的任务或执行失败做出反应，协调`checkpoints`，协调故障恢复，等等。

这个过程由三个不同的部分组成：

* ResourceManager
  <br/>`ResourceManager`负责Flink集群中的资源`分配/释放（de-/allocation）`和`供给（provisioning ）` --
  它管理`task slots`，`task slots`是Flink集群中资源调度的`基本单位`。
  Flink为不同的环境和`资源providers(如 YARN、Kubernetes 和 standalone部署)`实现了多个`ResourceManager`。
  <span style="color:orange; ">在standalone安装中，ResourceManager只能分配可用的`TaskManagers`的`slots`
  ，不能自行启动新的`TaskManagers`。</span>
* Dispatcher
  <br/>`Dispatcher`提供了一个REST接口来提交Flink应用程序以供执行，并为每个提交的作业启动一个新的`JobMaster`。
  它还运行`Flink web`以提供有关作业执行的信息。
* JobMaster
  <br/>`JobMaster`负责管理单个`JobGraph`的执行。多个作业可以在Flink集群中同时运行，每个作业都有自己的`JobMaster`。

### TaskManagers

`TaskManagers`(也称为`worker`)执行数据流程的任务，缓冲和交换数据流。

`TaskManager`必须始终至少有一个。`TaskManager`中资源调度的最小单位是`task slot`。
`TaskManager`中`task slot`的个数反映了并发处理任务的个数。注意，多个`operators`可以在一个任务槽中执行(参见下文)。

## Tasks and Operator Chains

对于分布式执行，Flink将`operator`子任务链接在一起成为`task`。每个`task`由一个线程执行。
将操作符链接到任务中是一种有用的优化:它减少了线程间切换和缓冲的开销，并在减少延迟的同时提高了总体吞吐量。
可以配置链接行为;请参阅链接文档了解详细信息。




