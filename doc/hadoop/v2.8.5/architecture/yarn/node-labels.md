# YARN Node Labels

## 概述

`节点标签（Node label）`是对具有相似特征的节点进行分组的一种方式，应用程序可以指定在哪里运行。

* 一个节点只能有一个节点分区，因此一个集群被节点分区划分为几个不相交的子集群。
  默认情况下，节点属于`default分区(partition="")`。
* 用户需要配置`每个分区的多少资源`可以被`不同的队列`
  使用。有关详细信息，请参阅 [Capacity Scheduler](capacity-scheduler.md) & [Fair Scheduler](fair-scheduler.md)。
* 有两种类型的节点分区
    * 独占的（Exclusive）:容器将被分配给完全匹配节点分区的节点。(例如，请求`partition=x`将分配给具有`partition=x`
      的节点，请求`DEFAULT partition`将分配给`DEFAULT分区`节点)。
    * 非独占的（Non-exclusive）:如果分区是非独占的，它将空闲资源共享给请求`DEFAULT分区`的容器。

用户可以指定每个队列可以访问的`节点标签集`，一个应用程序只能使用包含该应用程序的队列可以访问的`节点标签子集`。

## 特性

* 集群分区：每个节点可以分配一个标签，因此集群将被划分为几个较小的不相交的分区。
* 队列上节点标签的ACL：用户可以在每个队列上设置可访问的节点标签，这样只有一些节点只能被特定的队列访问。
* 指定队列可以访问的分区资源百分比，例如:队列A可以访问label=hbase节点上30%的资源。这样的百分比设置将与现有的资源管理器一致。
* 在资源请求中指定所需的节点标签，只有当节点具有相同的标签时才会分配。如果没有指定节点标签要求，这样的资源请求将只在属于DEFAULT分区的节点上分配。
* 可操作性
    * 节点标签和节点标签映射可以通过RM重启恢复
    * 更新节点标签：管理员可以在RM运行时更新节点上的标签和队列上的标签
* 可以通过三种方式将`NM`映射到节点标签，但是在所有方法中，`Partition Label`都应该是RM中配置的有效节点标签列表中的一个。
    * 集中式（Centralized）:节点到标签的映射可以通过RM暴露的`CLI`、`REST`或`RPC`完成。
    * 分布式（Distributed）:节点到标签的映射将由在`NM中配置`的`Node labels Provider`设置。我们在YARN中有两个不同的Provider:
      基于脚本的Provider和基于配置的Provider。 对于脚本，可以给NM配置一个脚本路径，脚本可以发出该节点的标签。
      如果配置为config，则可以直接在yarn-site.xml文件中配置节点标签。这两个选项都支持标签映射的动态刷新。
    * 委派-集中式（Delegated-Centralized）:节点到标签的映射将由`RM中配置`的`Node labels Provider`设置。
      如果出于安全考虑，并希望避免大集群中每个节点通过RM接口进行交互时，使用此方式。在注册NM时从该接口获取标签，并支持定期刷新。

## 配置

### 1.配置ResourceManager开启节点标签功能

在yarn-site.xml中设置以下属性

| 属性                                  | 值                                                                                         |
|-------------------------------------|-------------------------------------------------------------------------------------------|
| yarn.node-labels.fs-store.root-dir  | hdfs://namenode:port/path/to/store/node-labels/                                           |
| yarn.node-labels.enabled            | true                                                                                      |
| yarn.node-labels.configuration-type | 设置节点标签的配置类型。管理员可以指定`Centralized`、`Distributed`或`Delegated-Centralized`。默认值为`centralized`。 |

<span style="color:orange; ">注意：</span>

* 确保`yarn.node-labels.fs-store.root-dir`目录已创建，且ResourceManager有权限访问。(通常使用`yarn`用户)
* 如果希望将`节点标签`存储到RM的本地文件系统（而不是HDFS），可以使用路径：file:///home/yarn/node-label

### 2.添加`节点标签列表`

* 执行`yarn rmadmin -addToClusterNodeLabels <label_1(exclusive=true/false),label_2(exclusive=true/false)...>`来添加节点标签。
* 如果没有指定`(exclusive=...)`， exclusive将默认为`true`。
* 运行`yarn cluster --list-node-labels`检查添加的节点标签是否在集群中可见。

### 3.删除`节点标签列表`

* 执行`yarn rmadmin -removeFromClusterNodeLabels <label1,label2,label3...>`来删除一个或多个节点标签。命令参数应该是要删除的节点标签的逗号分隔列表。

### 4.添加`节点到标签映射`

#### a）在 Centralized NodeLabel 设置中配置节点到标签的映射

执行`yarn rmadmin -replaceLabelsOnNode <node1[:port]=label1,label2 node2[:port]=label1,label2> [-failOnUnknownNodes]`。
将label1加入node1，将label2加入node2。如果没有指定端口，它会将标签添加到该节点上运行的所有nodemanager。
如果设置了option -failOnUnknownNodes，如果指定的节点未知，该命令将失败。

#### b）在 Distributed NodeLabel 设置中配置节点到标签的映射

| 属性                                                              | 值                                                                                                                                                                                                                                                                                                                 |
|-----------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.node-labels.configuration-type                             | 需要在RM中设置为`distributed`，以便从NM中配置的node labels Provider获取节点到标签的映射。                                                                                                                                                                                                                                                   |
| yarn.nodemanager.node-labels.provider                           | 当`yarn.node-labels.configuration-type`在RM中配置为`distributed`，管理员可以通过在NM中配置`config`、`script`或`provider类名`(该类需要继承`org.apache.hadoop.yarn.server.nodemanager.nodelabels.NodeLabelsProvider`)来配置节点标签的provider。<br/>如果配置了`config`，则使用`ConfigurationNodeLabelsProvider`;<br/>如果配置了`script`，则使用`ScriptNodeLabelsProvider`。 |
| yarn.nodemanager.node-labels.resync-interval-ms                 | NM与RM同步节点标签的时间间隔。NM每个间隔发送其加载的标签，伴随心跳一起发送给RM。即使没有修改标签，也需要重新同步，因为管理员可能已经删除了由NM提供的集群标签。默认为2分钟。                                                                                                                                                                                                                       |
| yarn.nodemanager.node-labels.provider.fetch-interval-ms         | 当`yarn.nodemanager.node-labels.provider`配置为`config`、`script`或`继承AbstractNodeLabelsProvider的类`，则定期从`节点标签provider`检索节点标签。此配置用于定义间隔时间。如果配置了-1，则仅在初始化期间从provider检索节点标签。默认为10分钟。                                                                                                                                       |
| yarn.nodemanager.node-labels.provider.fetch-timeout-ms          | 当`yarn.nodemanager.node-labels.provider`配置为`script`，此配置提供了`超时时间`，在超时后，将中断查询节点标签的脚本。默认为20分钟。                                                                                                                                                                                                                       |
| yarn.nodemanager.node-labels.provider.script.path               | 要运行的`节点标签脚本`。脚本输出以`NODE PARTITION:`开头的行将被视为节点标签Partition。如果多行脚本输出具有此模式，则将考虑最后一行。                                                                                                                                                                                                                                  |
| yarn.nodemanager.node-labels.provider.script.opts               | 传递给节点标签脚本的参数。                                                                                                                                                                                                                                                                                                     |
| yarn.nodemanager.node-labels.provider.configured-node-partition | 当`yarn.nodemanager.node-labels.provider`配置为`config`，`ConfigurationNodeLabelsProvider`从这个参数中获取节点标签。                                                                                                                                                                                                                |

#### c）在 Delegated-Centralized NodeLabel 设置中配置节点到标签的映射

| 属性                                                          | 值                                                                                                                                                                                                 |
|-------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.node-labels.configuration-type                         | 需要在RM中设置为`delegated-centralized`，以便RM从`节点标签Provider`获取节点到标签的映射。                                                                                                                                   |
| yarn.resourcemanager.node-labels.provider                   | 当`yarn.node-labels.configuration-type`配置为`delegated-centralized`，则管理员需要配置ResourceManager获取节点标签的类。已配置的类需要继承`org.apache.hadoop.yarn.server.resourcemanager.nodelabels.RMNodeLabelsMappingProvider`。 |
| yarn.resourcemanager.node-labels.provider.fetch-interval-ms | 当`yarn.node-labels.configuration-type`配置为`delegated-centralized`，则定期从`节点标签provider`检索节点标签。此配置用于定义间隔时间。如果配置了-1，则在每个节点注册后仅从provider检索一次节点标签。默认为30分钟。                                                |

### 5.配置节点标签的调度器（Scheduler）

`Capacity Scheduler`配置

| 属性                                                                                   | 值                                                                                                                                       |
|--------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| yarn.scheduler.capacity.<queue-path>.capacity                                        | 设置队列可以访问属于DEFAULT分区的节点的百分比。每个父节点下的直接子节点的DEFAULT容量之和必须等于100。                                                                             |
| yarn.scheduler.capacity.<queue-path>.accessible-node-labels                          | 管理员需要指定标签可以被每个队列访问，用逗号分隔，如"hbase,storm"表示队列可以访问标签hbase和storm。所有队列都可以访问不带标签的节点，无需指定。如果没有指定此字段，它将从父字段继承。如果想显式指定一个队列只能访问没有标签的节点，只需将值设置为空格。 |
| yarn.scheduler.capacity.<queue-path>.accessible-node-labels.<label>.capacity         | 设置队列可以访问属于<label>分区的节点的百分比。每个父级直系子级<label>容量之和必须等于100。默认值为0。                                                                            |
| yarn.scheduler.capacity.<queue-path>.accessible-node-labels.<label>.maximum-capacity | 类似于`yarn.scheduler.capacity.<queue-path>.maximum-capacity`，表示每个队列标签的最大容量。默认值为100。                                                       |
| yarn.scheduler.capacity.<queue-path>.default-node-label-expression                   | 比如将值设置为hbase：如果提交到队列的应用程序没有在其资源请求中指定节点标签，它将使用`hbase`作为默认的节点标签表达式。默认情况下，这是空的，因此应用程序将从没有标签的节点获取容器。                                        |

### 6.节点标签配置示例

假设有以下队列结构

~~~
                root
            /     |     \
     engineer   sales  marketing
~~~

在集群中有5个节点(主机名=h1..h5)，每个节点有24G内存，24个vcore。5个节点中有1个节点有GPU(假设是h5)。 那么管理员给h5添加了GPU标签。
假设用户有一个Capacity Scheduler配置，如下所示:<span style="color:orange; ">(为了可读性，这里使用`key=value`形式)</span>

~~~
yarn.scheduler.capacity.root.queues=engineering,marketing,sales
yarn.scheduler.capacity.root.engineering.capacity=33
yarn.scheduler.capacity.root.marketing.capacity=34
yarn.scheduler.capacity.root.sales.capacity=33

yarn.scheduler.capacity.root.engineering.accessible-node-labels=GPU
yarn.scheduler.capacity.root.marketing.accessible-node-labels=GPU

yarn.scheduler.capacity.root.engineering.accessible-node-labels.GPU.capacity=50
yarn.scheduler.capacity.root.marketing.accessible-node-labels.GPU.capacity=50

yarn.scheduler.capacity.root.engineering.default-node-label-expression=GPU
~~~

可以看到root.engineering/marketing/sales.capacity=33，因此每个队列可以保证资源等于不分区时资源的`1/3`。
所以每个队列都可以使用`h1到h4`的`1/3`资源。即`24 * 4 * (1/3) = (32G mem, 32 v核)`。

只有engineering/marketing队列有权限访问GPU分区(见root.<queue-name>.accessible-node-labels)

engineering/marketing队列都保证资源等于`分区=GPU`的资源的`1/2`。
所以它们每个都可以使用`h5`的`1/2`资源，即`24 * 0.5 = (12G mem, 12个v核)`。

<span style="color:orange; ">配置后，注意需要完成以下操作</span>

* 完成CapacityScheduler的配置后，执行`yarn rmadmin -refreshQueues`使更改生效。
* 进入`RM Web UI`的调度器页面，查看是否设置成功。

## 指定应用程序的节点标签（编码方式，不常用）

Application可以使用以下`Java API`来指定要请求的节点标签

* `ApplicationSubmissionContext.setNodeLabelExpression(..)`为应用的所有容器设置节点标签表达式。
* `ResourceRequest.setNodeLabelExpression(..)`为单个资源请求设置节点标签表达式。这可以覆盖`ApplicationSubmissionContext`
  中的节点标签表达式集
* 在`ApplicationSubmissionContext`中指定`setAMContainerResourceRequest.setNodeLabelExpression`表示AM（application
  master）容器的期望节点标签。

## 监控

### 通过web UI进行监控

* 节点页面:`http://RM-Address:port/cluster/nodes`，可以获得每个节点的标签
* 节点标签页面:`http://RM-Address:port/cluster/nodelabels`，可以获得类型(独占/非独占)，活动节点管理器的数量，每个分区的总资源

### 通过命令行进行监控

* 使用`yarn cluster --list-node-labels`获取集群中的标签。
* 使用`yarn node -status <NodeId>`获取节点状态，包括给定节点上的标签。

