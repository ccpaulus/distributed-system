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

下图中的示例数据流由五个子任务执行，因此有五个并行线程。

![](images/architecture/tasks_chains.svg)

## Task Slots and Resources

每个worker (TaskManager)是一个JVM进程，可以在单独的线程中执行一个或多个`subtasks`。
为了控制TaskManager接受多少任务，它有所谓的任务槽(至少一个)。

每个`task slot`代表`TaskManager`资源的一个固定子集。假设一个`TaskManager`有三个`task slot`，那每个`slot`
会分得`TaskManager`1/3的托管内存。
资源进行`Slotting`意味着`subtask`不会与来自其他作业的`subtasks`竞争托管内存，而是拥有一定数量的预留托管内存。
<span style="color:orange; ">注意，这里不会进行CPU隔离；目前，`slots`仅分隔任务的托管内存。</span>

通过调整`task slots`的数量，用户可以定义`subtasks`彼此隔离的方式。
每个`TaskManager`有一个`slot`意味着每个任务组在单独的JVM中运行(例如，可以在单独的容器中启动)。
拥有多个`slots`意味着更多的子任务共享同一个JVM。同一JVM中的`Tasks`共享TCP连接(通过多路复用)和心跳消息。
它们还可以共享数据集和数据结构，从而减少每个任务的开销。

![](images/architecture/tasks_slots.svg)

默认情况下，Flink允许子任务共享插槽，即使它们是不同任务的子任务，只要它们来自相同的作业。结果是一个槽可以容纳整个作业的管道。允许此插槽共享有两个主要好处

* Flink集群需要的任务槽正好与作业中使用的最高并行度相同。不需要计算一个程序总共包含多少个任务(具有不同的并行度)。
*

![](images/architecture/slot_sharing.svg)

## Flink Application Execution

Flink应用程序是从其main()方法生成一个或多个Flink作业的任何用户程序。这些作业的执行可以在本地JVM (LocalEnvironment)
中进行，也可以在具有多台机器的集群的远程设置中进行(RemoteEnvironment)
。对于每个程序，ExecutionEnvironment提供了控制作业执行(例如设置并行度)和与外部世界交互的方法(参见Flink程序的剖析)。

Flink应用程序的作业可以提交到长时间运行的Flink会话集群、专用Flink作业集群(已弃用)
或Flink应用程序集群。这些选项之间的区别主要与集群的生命周期和资源隔离保证有关。

### Flink Application Cluster

* 集群生命周期（Cluster Lifecycle）：Flink应用程序集群是一个专用的Flink集群，它只执行来自一个Flink应用程序的任务，并且main()
  方法在集群上而不是在客户端上运行。作业提交是一个一步到位的过程:
  您不需要先启动Flink集群，然后将作业提交到现有的集群会话;相反，您可以将应用程序逻辑和依赖项打包到一个可执行的作业JAR中，集群入口点(
  ApplicationClusterEntryPoint)负责调用main()方法来提取JobGraph。
  例如，这允许您像部署Kubernetes上的任何其他应用程序一样部署Flink应用程序。因此，Flink应用程序集群的生存期与Flink应用程序的生存期绑定在一起。
* 资源隔离（Resource Isolation）：在Flink应用程序集群中，ResourceManager和Dispatcher的作用域为单个Flink应用程序，这比Flink会话集群提供了更好的关注点分离。

### Flink Session Cluster

*

集群生命周期：在Flink会话集群中，客户端连接到可以接受多个作业提交的预先存在的、长期运行的集群。即使在所有作业都完成之后，集群(
和JobManager)仍将继续运行，直到会话被手动停止。因此，Flink会话集群的生存期不绑定到任何Flink作业的生存期。

*

资源隔离：TaskManager槽位由ResourceManager在作业提交时分配，作业完成后释放。由于所有作业都共享同一个集群，因此在提交作业阶段存在对集群资源(
如网络带宽)的竞争。这种共享设置的一个限制是，如果一个TaskManager崩溃，那么在这个TaskManager上运行任务的所有作业都将失败;同样，如果在JobManager上发生一些致命错误，它将影响集群中运行的所有作业。

* 其他注意事项（Other
  considerations）：拥有一个预先存在的集群可以节省大量申请资源和启动taskmanager的时间。在作业的执行时间非常短，并且高启动时间会对端到端用户体验产生负面影响的场景中，这一点很重要，例如短查询的交互式分析，在这种情况下，作业可以使用现有资源快速执行计算。

以前，Flink会话集群也称为会话模式下的Flink集群。

### Flink Job Cluster (deprecated)

单任务模式只被YARN支持，在Flink 1.15中已被弃用。它将被投放在FLINK-26000。请考虑应用程序模式，在YARN上每个作业启动一个专用集群。

* 集群生命周期：在Flink作业集群中，可用的集群管理器(如YARN)
  用于为每个提交的作业启动集群，并且该集群仅对该作业可用。在这里，客户机首先从集群管理器请求资源以启动JobManager，然后将作业提交给运行在该进程中的Dispatcher。然后根据作业的资源需求惰性地分配任务管理器。作业完成后，Flink作业集群将被拆除。
* 资源隔离：JobManager中的致命错误只影响在该Flink作业集群中运行的一个作业。
* 其他注意事项：由于ResourceManager需要申请并等待外部资源管理组件启动TaskManager进程并分配资源，所以Flink Job
  cluster更适合于长时间运行、对稳定性要求高且对较长启动时间不敏感的大型作业。

以前，Flink作业集群在作业(或每个作业)模式下也称为Flink集群。

Flink作业集群仅支持YARN。



