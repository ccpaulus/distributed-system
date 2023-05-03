# Fair Scheduler

`FairScheduler`，一个用于Hadoop的可插拔调度程序，它允许YARN应用程序在大型集群中公平地共享资源。

## 简介

公平调度是一种将资源分配给应用程序的方法，这样所有应用程序在一段时间内平均获得相等的资源份额。默认情况下，公平调度程序仅基于内存的调度公平性决策。
它可以配置为使用内存和CPU进行调度，使用Ghodsi等人开发的优势资源公平概念。当只有一个应用程序在运行时，该应用程序将使用整个集群。
当提交其他应用程序时，释放的资源被分配给新应用程序，因此每个应用程序最终获得大致相同数量的资源。
与默认的Hadoop调度程序不同，它会形成一个`应用程序队列`，它可以让`短应用`程序在合理的时间内完成，而不会饿死`长应用`程序。
在多个用户之间共享集群也是一种合理的方式。最后，公平分享也适用于应用程序优先级——优先级被用作权重，以确定每个应用程序应该获得的总资源比例。

调度程序将应用程序进一步组织到“队列”中，并在这些队列之间公平地共享资源。默认情况下，所有用户共享一个名为“default”的队列。
如果一个应用程序在容器资源请求中特别列出了一个队列，那么该请求将被提交到该队列。还可以通过配置根据请求中包含的用户名分配队列。
在每个队列中，调度策略用于在运行的应用程序之间共享资源。默认为基于内存的公平共享，但也可以配置先进先出和具有优势资源公平的多资源。
可以将队列安排在层次结构中以划分资源，并配置权重以按特定比例共享集群。

除了提供公平共享之外，`fair Scheduler`还允许为队列分配有保证的最小共享，这对于确保某些用户、组或生产应用程序始终获得足够的资源非常有用。
当队列包含应用程序时，它至少获得其最小份额，但当队列不需要其全部保证份额时，多余的份额将在其他运行的应用程序之间分配。
这允许调度器保证队列的容量，同时在这些队列不包含应用程序时有效地利用资源。

`Fair Scheduler`默认允许所有应用程序运行，但也可以通过配置文件限制每个用户和每个队列运行的应用程序数量。
这在用户必须一次提交数百个应用程序时非常有用，或者在同时运行太多应用程序会导致创建太多中间数据或太多上下文切换的情况下，通常可以提高性能。
限制应用程序不会导致任何随后提交的应用程序失败，只是在调度程序的队列中等待，直到一些用户早期的应用程序完成。

## 分层队列

公平调度程序支持分层队列。所有队列都是从名为“root”的队列派生的。可用资源以典型的公平调度方式在根队列的子队列之间分配。
然后，孩子们以同样的方式将分配给他们的资源分配给他们的孩子。应用程序只能被安排在叶子队列上。
通过将队列作为父队列的子元素放置在公平调度程序分配文件中，可以将队列指定为其他队列的子队列。

<span style="color:green">分层队列命名规则与`CapacityScheduler`分层队列命名规则一致</span>

公平调度程序允许为每个队列设置不同的自定义策略，以允许以用户想要的任何方式共享队列的资源。
可以通过扩展`org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.SchedulingPolicy`来构建自定义策略。
FifoPolicy、FairSharePolicy(默认)和DominantResourceFairnessPolicy都是内置的策略，可以随时使用。

## 自动将应用程序放入队列

`Fair Scheduler`允许管理员配置策略，自动将提交的应用程序放入适当的队列中。位置可以取决于提交者的用户和组以及应用程序传递的请求队列。
策略由一组规则组成，依次应用这些规则对传入的应用程序进行分类。每个规则要么将应用放入队列，要么拒绝它，要么继续执行下一个规则。
有关如何配置这些策略，请参阅下面的分配文件格式。

## 开启公平调度

要使用公平调度程序，首先在yarn-site.xml中分配适当的调度程序类:

~~~
<property>
  <name>yarn.resourcemanager.scheduler.class</name>
  <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler</value>
</property>
~~~

## 配置

自定义`Fair Scheduler`通常涉及修改两个文件。首先，可以通过在现有配置目录中的yarn-site.xml文件中添加配置属性来设置调度器范围的选项。
其次，在大多数情况下，用户都希望创建一个分配文件，列出存在哪些队列以及它们各自的权重和容量。分配文件每10秒重新加载一次，允许动态地进行更改。

* yarn-site.xml 属性

| 属性                                                           | 描述                                                                                                                                                                         |
|--------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.scheduler.fair.allocation.file                          | 分配文件的路径。分配文件是一个XML清单，除了某些策略默认值之外，还描述了队列及其属性。该文件必须采用XML格式。如果给出了相对路径，则在类路径(通常包括Hadoop conf目录)上搜索文件。默认为fair-scheduler.xml。                                                    |
| yarn.scheduler.fair.user-as-default-queue                    | 如果没有指定队列名，是否使用与分配关联的用户名作为默认队列名。如果设置为“false”或不设置，则所有作业都有一个共享的默认队列，名为“default”。默认为true。如果在分配文件中给出队列放置策略，则忽略此属性。                                                              |
| yarn.scheduler.fair.preemption                               | 是否使用抢占。默认为false。                                                                                                                                                           |
| yarn.scheduler.fair.preemption.cluster-utilization-threshold | 占用阈值，超过该阈值，抢占开始生效。利用率计算为所有资源中使用率与容量的最大比率。默认为0.8f。                                                                                                                          |
| yarn.scheduler.fair.sizebasedweight                          | 是否根据单个应用的大小分配份额，而不是不分大小为所有应用提供平等的份额。当设置为true时，应用程序的权重是1的自然对数加上应用程序请求的总内存，除以2的自然对数。默认为false。                                                                                |
| yarn.scheduler.fair.assignmultiple                           | 是否允许在一次心跳中分配多个容器。默认为false。                                                                                                                                                 |
| yarn.scheduler.fair.dynamic.max.assign                       | 如果`assignmultiple`为true，是否动态确定在一次心跳中可以分配的资源量。打开后，节点上大约一半未分配的资源会在一次心跳中分配给容器。默认为true。                                                                                        |
| yarn.scheduler.fair.max.assign                               | 如果`assignmultiple`为true, `dynamic.max.assign`为false，则一次心跳中可以分配的容器的最大数量。默认为-1，没有设置限制。                                                                                       |
| yarn.scheduler.fair.locality.threshold.node                  | 对于请求特定节点上容器的应用程序，从最后一次容器分配开始等待的调度机会的数量，然后再接受另一个节点上的放置。表示为0到1之间的浮点数，作为集群大小的一部分，它是要放弃的调度机会的数量。默认值-1.0表示不放弃任何调度机会。                                                            |
| yarn.scheduler.fair.locality.threshold.rack                  | 对于请求特定机架上容器的应用程序，从最后一次容器分配开始等待的调度机会的数量，然后再接受另一个机架上的放置。表示为0到1之间的浮点数，作为集群大小的一部分，它是要放弃的调度机会的数量。默认值-1.0表示不放弃任何调度机会。                                                            |
| yarn.scheduler.fair.allow-undeclared-pools                   | 如果为true，则可以在应用程序提交时创建新的队列，无论是因为提交者将它们指定为应用程序的队列，还是因为它们是由user-as-default-queue属性放置在那里的。如果该值为false，则任何时候应用程序将被放置在分配文件中未指定的队列中，它将被放置在“默认”队列中。默认为true。如果在分配文件中给出队列放置策略，则忽略此属性。 |
| yarn.scheduler.fair.update-interval-ms                       | 锁定调度器并重新计算公平份额、重新计算需求和检查是否有抢占到期的时间间隔。默认为500毫秒。                                                                                                                             |

* allocation.file 格式

分配文件必须是XML格式。 例：

~~~
<?xml version="1.0"?>
<allocations>
  <queue name="sample_queue">
    <minResources>10000 mb,0vcores</minResources>
    <maxResources>90000 mb,0vcores</maxResources>
    <maxRunningApps>50</maxRunningApps>
    <maxAMShare>0.1</maxAMShare>
    <weight>2.0</weight>
    <schedulingPolicy>fair</schedulingPolicy>
    <queue name="sample_sub_queue">
      <aclSubmitApps>charlie</aclSubmitApps>
      <minResources>5000 mb,0vcores</minResources>
    </queue>
  </queue>

  <queueMaxAMShareDefault>0.5</queueMaxAMShareDefault>
  <queueMaxResourcesDefault>40000 mb,0vcores</queueMaxResourcesDefault>

  <!-- Queue 'secondary_group_queue' is a parent queue and may have
       user queues under it -->
  <queue name="secondary_group_queue" type="parent">
  <weight>3.0</weight>
  </queue>

  <user name="sample_user">
    <maxRunningApps>30</maxRunningApps>
  </user>
  <userMaxAppsDefault>5</userMaxAppsDefault>

  <queuePlacementPolicy>
    <rule name="specified" />
    <rule name="primaryGroup" create="false" />
    <rule name="nestedUserQueue">
        <rule name="secondaryGroupExistingQueue" create="false" />
    </rule>
    <rule name="default" queue="sample_queue"/>
  </queuePlacementPolicy>
</allocations>
~~~

* 队列访问ACL
  <br/>略

* 预占ACL
  <br/>略

详见[官网文档](https://hadoop.apache.org/docs/r2.8.5/hadoop-yarn/hadoop-yarn-site/FairScheduler.html)

## 管理

* 在运行时修改配置
  <br/>在运行时修改allocation.file，可以在运行时修改最小共享、限制、权重、抢占超时和队列调度策略。调度器将在看到该文件被修改后10-15秒重新加载该文件。

* 通过web UI进行监控
  通过ResourceManager的web界面http://*ResourceManager URL*/cluster/scheduler可以查看当前的应用程序、队列和公平共享。

* 在队列之间移动应用程序
  <br/>Fair Scheduler支持将正在运行的应用程序移动到另一个队列。这对于将重要的应用程序移动到高优先级队列或将不重要的应用程序移动到低优先级队列非常有用。
  应用程序可以通过运行`yarn application -movetoqueue appID -queue targetQueueName`来移动。

  当应用程序移动到一个队列时，为了确保公平性，将其现有分配与新队列的分配一起计算，而不是与旧队列的分配一起计算。
  如果将应用程序的资源添加到队列会违反其maxRunningApps或maxResources约束，那么将应用程序移动到队列的尝试将失败。

