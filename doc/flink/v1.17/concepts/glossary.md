# Glossary（术语表）

## Checkpoint Storage

`State Backend`在`checkpoint`期间存储`snapshot`的位置(`JobManager的Java堆`或`Filesystem`)。

## Flink Application Cluster

一个专用的`Flink Cluster`，它只执行同一个`Flink Application`的`Flink Job`。
`Flink Cluster`的生存期与`Flink Application`的生存期绑定。

## Flink Job Cluster

一个专用的`Flink Cluster`，它只执行一个`Flink Job`。`Flink Cluster`与`Flink Job`的生存期绑定。
这种部署模式自`Flink 1.15`后已弃用。

## Flink Cluster

通常由 一个`JobManager`进程 和 一个或多个`Flink TaskManager`进程 组成的`分布式系统`。

## Event

`Event`是关于应用程序建模的域状态变化的声明。`Event`可以是`流式处理`或`批处理`的`输入或是输出`。
`Event`是一种特殊类型的`Record`。

## ExecutionGraph

见`Physical Graph`

## Function

函数由用户实现，封装了Flink程序的应用逻辑。大多数函数都由相应的`Operator`包装。

## Instance

术语`instance`用于描述运行时特定类型(通常是`Operator`或`Function`)的特定实例。
由于`Apache Flink`主要是用Java编写的，这对应于Java中实例或对象的定义。
在`Apache Flink`上下文中，术语`parallel instance`也经常用于强调同一`Operator`或`Function`的`多个实例`并行运行。

## Flink Application

`Flink Application`是一个Java应用程序，它通过`main()方法(或其他方式)`提交一个或多个`Flink Job`。
提交作业通常通过在执行环境中调用`execute()`来完成。

应用程序的作业可以提交到长时间运行的`Flink Session Cluster`、专用`Flink Application Cluster`或`Flink Job Cluster`。

## Flink Job

`Flink Job`是通过调用`Flink Application`中的`execute()`创建和提交的`逻辑图(通常也称为数据流图，dataflow graph)`的运行时表示。

## JobGraph

见`Logical Graph`

## Flink JobManager

`JobManager`是`Flink Cluster`的编排器（orchestrator）。
它包含三个不同的组件:`Flink Resource Manager`，`Flink Dispatcher`和一个`Flink JobMaster`。

## Flink JobMaster

`JobMaster`是运行在`JobManager`中的组件之一。`JobMaster`负责监督单个作业的Tasks的执行。

## JobResultStore

`JobResultStore`是一个Flink组件，它将全局终止的(即完成、取消或失败)作业的结果持久化到文件系统中，允许结果比完成的作业存活得更久。
然后Flink使用这些结果来确定作业是否应该在高可用性集群中进行恢复。

## Logical Graph

`Logical Graph`是一个有向图，图的节点是`Operators`，图的边用来定义`Operators`和`对应的数据流或数据集`的输入/输出关系。
通过从Flink应用程序提交作业来创建`Logical Graph`。

## Managed State（托管状态）

`Managed State`描述已在框架中注册的应用程序状态。对于`Managed State`，`Apache Flink`将关注持久性和重新伸缩等问题。

## Operator

`Logical Graph`的节点。`Operator`执行某种操作，该操作通常由`Function`执行。
`Source`和`Sink`是用于数据`摄取`和`输出`的特殊`Operator`。

## Operator Chain

一个`Operator Chain`由两个或多个连续的`Operator`组成，它们之间没有`重分区（repartitioning）`。
同一`Operator Chain`中的`Operator`直接将`records`转发给对方，而无需经过`序列化`或Flink的`网络堆栈`。

## Partition

`Partition`是整个`数据流`或`数据集`的独立子集。通过将每条记录分配给一个或多个`Partition`
，将`数据流`或`数据集`划分为多个`Partition`。
`数据流`或`数据集`的`Partition`在运行时由`Tasks`消费。改变`数据流`或`数据集`分区方式的`转换（transformation）`
通常称为`重分区（repartitioning）`。

## Physical Graph

`Physical Graph`是将`Logical Graph`转换为在分布式运行时中`执行（execution ）`的结果。
图的节点是`Tasks`，图的边是`对应的数据流或数据集`的输入/输出关系。

## Record

`Records`是`数据集`或`数据流`的组成元素。`Operators`和`Functions`接收`records`作为输入，并发出`records`作为输出。

## (Runtime) Execution Mode

`DataStream API`程序可以以两种执行模式之一执行:`BATCH`或`STREAMING`。有关详细信息，请参见[Execution Mode]。

## Flink Session Cluster

一个`长时间运行（long-running）`的`Flink Cluster`，它接受多个`Flink Jobs`进行执行。
此`Flink Cluster`的生存期不与任何`Flink Job`的生存期绑定。
以前，`Flink Session Cluster`也称为`会话模式`下的`Flink Cluster`。

## State Backend

对于流式处理程序，`Flink Job`的`State Backend`决定了它的`state`如何存储在每个TaskManager (`TaskManager的Java堆`
或`(嵌入式)RocksDB`)上。

## Sub-Task

`Sub-Task`是负责处理数据流分区的`Task`。术语`Sub-Task`强调了同一`Operator`或`Operator Chain`有多个并行`Tasks`。

## Table Program

用Flink的关系API(`Table API`或`SQL`)声明的管道的通用术语。

## Task

`Physical Graph`的节点。`Task`是工作的基本单元，由Flink的运行时执行。任务精确地封装了一个`Operator`或`Operator Chain`的并行实例。

## Flink TaskManager

`TaskManagers`是`Flink Cluster`的工作进程。`Tasks`被调度到`TaskManagers`中执行。它们相互通信以在后续任务之间交换数据。

## Transformation

`Transformation`应用于一个或多个`数据流`或`数据集`，并产生一个或多个输出`数据流`或`数据集`。
`Transformation`可能会在每个`record`的基础上更改`数据流`或`数据集`，但也可能只更改其`分区`或执行`聚合`。
`Operators`和`Functions`是`Flink API`的物理部分，而`Transformations`只是一个API概念。
具体来说，大多数转换都是由某些`Operators`实现的。

## UID

`Operator`的唯一标识符，由用户提供或由作业结构确定。提交应用程序时，将其转换为`UID hash`。

## UID hash

`Operator`在运行时的唯一标识符，也称为`Operator ID`或`Vertex ID`，由UID生成。
它通常暴露在`logs`、`REST API`或`metrics`中，最重要的是用于在`savepoints`内识别`operators`。

