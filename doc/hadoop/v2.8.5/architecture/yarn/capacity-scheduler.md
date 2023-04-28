# CapacityScheduler

`CapacityScheduler`，一个用于Hadoop的可插拔调度程序，它允许多个租户安全地共享一个大型集群，这样他们的应用程序就可以在分配容量的限制下及时地分配资源。

## 特征

* 分层队列：支持分层队列，以确保在允许其他队列使用空闲资源之前在组织的子队列之间共享资源，从而提供更多的控制和可预测性。
* 容量保证：队列被分配了容量的一部分。提交到队列的所有应用程序都可以访问分配给队列的容量。管理员可以对分配给每个队列的容量配置软限制和可选的硬限制。
* 安全性：每个队列都有严格的acl，它控制哪些用户可以向各个队列提交应用程序。此外，还有安全防护措施，以确保用户不能查看和/或修改来自其他用户的应用程序。此外，还支持每个队列和系统管理员角色。
* 弹性：可以将空闲资源分配给超出其容量的任何队列。当运行的队列容量不足时，将空闲下来的资源分配给这些队列上的应用程序(
  也支持抢占)。这确保了资源以可预测和弹性的方式对队列可用，从而防止集群中人为的资源孤岛，从而有助于利用率。
* 多租户：提供了一组全面的限制，以防止单个应用程序、用户和队列独占队列或整个集群的资源，以确保集群不会不堪重负。
* 可操作性：
    * 运行时配置：管理员可以在运行时以安全的方式更改队列定义和属性(如容量、acl)
      ，以尽量减少对用户的干扰。此外，还为用户和管理员提供了一个控制台，以查看系统中各种队列的当前资源分配情况。管理员可以在运行时添加其他队列，但不能在运行时删除队列。
    * 清空应用程序：管理员可以在运行时停止队列。如果队列处于STOPPED状态，则不能将新的应用程序提交给队列或它的任何子队列。现有的应用程序将继续完成，因此队列可以优雅地清空。管理员还可以启动已停止的队列。
* 基于资源（内存）的调度：支持资源密集型应用程序，其中应用程序可以选择指定比默认值更高的资源需求，从而容纳具有不同资源需求的应用程序。
* 基于用户或组的队列映射：此功能允许用户将作业映射到基于用户或组的特定队列。
* 优先级调度：此功能允许以不同的优先级提交和调度应用程序。整数值越大，优先级越高。目前，应用程序优先级仅支持FIFO排序策略。

## 配置

### 设置ResourceManager使用CapacityScheduler

要配置ResourceManager使用CapacityScheduler，请在conf/yarn-site.xml中设置以下属性:

~~~
<property>
  <name>yarn.resourcemanager.scheduler.class</name>
  <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
</property>
~~~

### 设置队列

CapacityScheduler有一个名为root的预定义队列。系统中的所有队列都是`root队列`的子队列。
<br/>通过配置`yarn.scheduler.capacity.root.queues`属性，可以设置更多的`子队列`，子队列名称为以`,`分隔。
<br/>CapacityScheduler使用一个称为`队列路径`的概念来配置队列的层次结构。队列路径是队列层次结构的完整路径，从`root`
开始，使用`.`作为分隔符。
<br/>子队列不会直接从父队列继承属性。

以下为 root 子队列 [a,b,c] 以及 a、b 的子队列 [a1,a2] 和 [b1,b2,b3]

~~~
# root队列
<property>
  <name>yarn.scheduler.capacity.root.queues</name>
  <value>a,b,c</value>
  <description>The queues at the this level (root is the root queue).
  </description>
</property>

# root子队列-a
<property>
  <name>yarn.scheduler.capacity.root.a.queues</name>
  <value>a1,a2</value>
  <description>The queues at the this level (root is the root queue).
  </description>
</property>

# root子队列-b
<property>
  <name>yarn.scheduler.capacity.root.b.queues</name>
  <value>b1,b2,b3</value>
  <description>The queues at the this level (root is the root queue).
  </description>
</property>
~~~

### 队列属性

* 资源分配

| 属性                                                                    | 描述                                                                                                                                                                                                                                                           |
|-----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.scheduler.capacity.<queue-path>.capacity                         | 队列容量以百分比(%)表示，为浮点数(例如12.5)。每个级别上所有队列的容量总和必须等于100。如果有空闲资源，队列中的application可能会消耗比队列容量更多的资源，从而提供弹性。                                                                                                                                                              |
| yarn.scheduler.capacity.<queue-path>.maximum-capacity                 | 最大队列容量，以百分比(%)为浮点数。这会限制队列中application的弹性。`默认为-1，表示禁用`。                                                                                                                                                                                                       |
| yarn.scheduler.capacity.<queue-path>.minimum-user-limit-percent       | 如果有资源需求，每个队列在任何给定时间都对分配给用户的资源百分比实施限制。用户限制可以在最小值和最大值之间变化。前者(最小值)设置为该属性值，后者(最大值)取决于提交application的用户数量。例如，假设这个属性的值是25。如果两个用户同时向队列提交申请，单个用户使用的资源不能超过队列资源的50%。如果有第三个用户提交一个应用程序，单个用户不能使用超过33%的队列资源。对于4个或更多用户，任何用户都不能使用超过25%的队列资源。值100表示不施加用户限制。默认值是100。Value指定为整数。 |
| yarn.scheduler.capacity.<queue-path>.user-limit-factor                | 队列容量的倍数，可以配置为允许单个用户获取更多资源。默认情况下，该值设置为`1`，以确保单个用户永远不会占用超过队列配置的容量，而不管集群有多少空闲资源。Value指定为浮点数。                                                                                                                                                                    |
| yarn.scheduler.capacity.<queue-path>.maximum-allocation-mb            | 队列向资源管理器申请分配给每个容器的最大内存限制。此设置覆盖集群配置`yarn.scheduler.maximum-allocation-mb`。该值必须小于或等于集群的最大值。                                                                                                                                                                    |
| yarn.scheduler.capacity.<queue-path>.maximum-allocation-vcores        | 队列向资源管理器申请分配给每个容器的最大虚拟核数限制。此设置覆盖集群配置`yarn.scheduler.maximum-allocation-vcores`。该值必须小于或等于集群的最大值。                                                                                                                                                              |
| yarn.scheduler.capacity.<queue-path>.user-settings.<user-name>.weight | 此浮点值用于计算`队列中用户的限制资源值`时使用。此值将使每个用户的权重大于或小于队列中的其他用户。例如，如果用户A在队列中应该比用户B和C多接收50%的资源，则用户A的此属性将设置为1.5，用户B和C将默认为1.0。                                                                                                                                                |

* 正在运行和挂起的应用程序限制

| 属性                                                                                                                     | 描述                                                                                                                                                                                                                |
|------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.scheduler.capacity.maximum-applications / yarn.scheduler.capacity.<queue-path>.maximum-applications               | 系统中可以同时活动(正在运行和挂起)的application的最大数量。每个队列的限制与它们的队列容量和用户限制成正比。这是一个硬性限制，任何超过此限制的申请都将被拒绝。默认为10000。这可以通过yarn.scheduler.capacity为所有队列设置。也可以通过设置yarn.scheduler.capacity.<queue-path>.maximum-applications来覆盖每个队列的值。值为整数。 |
| yarn.scheduler.capacity.maximum-am-resource-percent / yarn.scheduler.capacity.<queue-path>.maximum-am-resource-percent | 集群中可用于运行AM的最大资源百分比，用于控制并发活动application的数量。每个队列的限制与它们的队列容量和用户限制成正比。指定为浮点数-即0.5 = 50%。默认值为10%。这可以通过yarn.scheduler.capacity为所有队列设置。也可以通过设置yarn.scheduler.capacity.<queue-path>.maximum-am-resource-percent来覆盖每个队列的值。 |

* 队列管理和权限

| 属性                                                                | 描述                                                                                                                                                           |
|-------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.scheduler.capacity.<queue-path>.state                        | 队列的状态。可以是RUNNING或STOPPED。如果队列处于STOPPED状态，则不能将新的application提交给它自己或它的任何子队列。因此，如果根队列处于STOPPED状态，则不能向整个集群提交任何application。现有的application将继续完成，因此可以正常地耗尽队列。值指定为枚举。 |
| yarn.scheduler.capacity.root.<queue-path>.acl_submit_applications | ACL控制谁可以向给定队列提交application。如果给定用户/组对给定队列或层次结构中的父队列之一具有必要的acl，则可以提交application。如果未指定此属性的acl，则从父队列继承。                                                          |
| yarn.scheduler.capacity.root.<queue-path>.acl_administer_queue    | ACL控制谁可以管理给定队列上的application。如果给定用户/组对给定队列或层次结构中的父队列之一具有必要的acl，则它们可以管理application。如果未指定此属性的acl，则从父队列继承。                                                       |

其余配置，详见[官网文档](https://hadoop.apache.org/docs/r2.8.5/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html)

### 更改队列配置

编辑`conf/capacity-scheduler.xml`文件，并执行`yarn rmadmin -refreshQueues`命令

<span style="color:red ">
不能删除队列，只支持添加新队列，且更新后的队列配置必须是有效的，即每个级别的队列容量和应该等于100%。</span>

