# NodeManager

NodeManager负责启动和管理节点上的容器。容器执行AppMaster指定的任务。

## 健康状况检查服务

NodeManager运行服务以确定其正在执行的节点的健康状况。这些服务对磁盘执行检查以及任何用户指定的测试。
如果任何健康检查失败，NodeManager将该节点标记为不健康，并将此信息通知ResourceManager，然后ResourceManager停止向该节点分配容器。
节点状态的通信是作为NodeManager和ResourceManager之间心跳的一部分完成的。`磁盘检查器`和`运行状况监控器`(将在下面介绍)
的运行间隔不会影响心跳间隔。
当心跳发生时，将使用这两项检查的状态来确定节点的健康状况。

### 磁盘检查器

磁盘检查器检查配置NodeManager使用的磁盘的状态(`local-dirs`和`log-dirs`，使用`yarn.nodemanager.local-dirs`
和`yarn.nodemanager.log-dirs`配置)。
检查包括`权限`和`空闲磁盘空间`，以及`检查文件系统`是否处于`只读状态`。默认情况下，检查每隔2分钟运行一次，但可以根据用户的需要配置为频繁运行。
如果磁盘检查失败，NodeManager将停止使用该磁盘，但仍将节点状态报告为健康状态。
但是，如果有许多磁盘未能通过检查(数量可以配置，如下所述)，则向ResourceManager报告该节点不健康，并且不会为该节点分配新的容器。

可以通过以下配置参数修改磁盘检查:

| 属性                                                                            | 允许值                 | 描述                                                                               |
|-------------------------------------------------------------------------------|---------------------|----------------------------------------------------------------------------------|
| yarn.nodemanager.disk-health-checker.enable                                   | true, false         | 启用或禁用磁盘健康检查器服务                                                                   |
| yarn.nodemanager.disk-health-checker.interval-ms                              | Positive integer    | 磁盘检查器应该运行的时间间隔，以毫秒为单位;缺省值是2分钟                                                    |
| yarn.nodemanager.disk-health-checker.min-healthy-disks                        | Float between 0-1   | 为使NodeManager将节点标记为健康状态，必须通过检查的最小磁盘比例;默认值是0.25                                   |
| yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage | Float between 0-100 | 在磁盘被磁盘检查器服务标记为不健康之前可以使用的磁盘空间的最大百分比。该检查将对NodeManager使用的每个磁盘运行。默认值为90，即90%的磁盘可以被使用 |
| yarn.nodemanager.disk-health-checker.min-free-space-per-disk-mb               | Integer             | 磁盘检查器服务将磁盘标记为健康状态时磁盘上必须可用的最小可用空间量。该检查将对NodeManager使用的每个磁盘运行。默认值为0，即可以使用整个磁盘      |

### 外部的健康状况脚本

用户可以指定自己的健康状况检查器脚本，该脚本将由健康状况检查器服务调用。用户可以指定超时以及要传递给脚本的选项。
如果脚本以非零退出退出码(`non-zero exit code`)、超时或导致抛出异常，则将节点标记为不健康。
请注意，如果脚本由于权限或路径错误等原因无法执行，则将其视为失败，节点将被报告为不健康。
请注意，指定健康状况检查脚本不是强制性的。如果未指定脚本，则仅使用磁盘检查器状态来确定节点的健康状况。

可通过以下配置参数设置健康脚本:

| 属性                                                | 允许值              | 描述                                 |
|---------------------------------------------------|------------------|------------------------------------|
| yarn.nodemanager.health-checker.interval-ms       | Positive integer | 健康状况检查器服务运行的时间间隔(以毫秒为单位);缺省值为10分钟。 |
| yarn.nodemanager.health-checker.script.timeout-ms | Positive integer | 执行的健康状况脚本的超时时间;缺省值是20分钟。           |
| yarn.nodemanager.health-checker.script.path       | String           | 要运行的健康状况检查脚本的绝对路径。                 |
| yarn.nodemanager.health-checker.script.opts       | String           | 执行脚本时传递给脚本的参数。                     |

## NodeManager重启

NodeManager重启特性使NodeManager能够在不丢失节点上运行的活动容器的情况下重新启动。
在高层次上，NM在处理容器管理请求时将任何必要的状态存储到本地状态存储中。
当NM重新启动时，它通过首先加载各个子系统的状态进行恢复，然后让这些子系统使用加载状态执行恢复。

### 启用NM重启

步骤1：要启用`NM Restart`功能，请将`conf/yarn-site.xml`中的以下属性设置为true。

| 属性                                | 值                  |
|-----------------------------------|--------------------|
| yarn.nodemanager.recovery.enabled | true，(默认值设置为false) |

步骤2：配置NodeManager保存运行状态的本地文件系统目录路径。

| 属性                            | 描述                                                                  |
|-------------------------------|---------------------------------------------------------------------|
| yarn.nodemanager.recovery.dir | 启用恢复时节点管理器将在其中存储状态的本地文件系统目录。默认值为`$hadoop.tmp.dir/yarn-nm-recovery`。 |

步骤3：为NodeManager配置有效的RPC地址。

| 属性                       | 描述                                                                                                                                                                                  |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.nodemanager.address | 使用`yarn.nodemanager.address`指定NodeManager的RPC服务器时，不能使用临时端口(默认端口0)，因为NM在重启之前和之后端口会发生变化。这将中断重启前与NM通信的所有客户端。启用NM重启的前提条件是，显式地将`yarn.nodemanager.address`设置为具有特定端口号的地址(例如0.0.0.0:45454)。 |

步骤4：辅助服务。

* YARN集群中的nodemanager可以配置为运行辅助服务(`auxiliary services`)。对于功能完整的NM重启，YARN可以依赖于任何也支持恢复的辅助服务。
  这通常包括：
    * 1)避免使用临时端口，以便以前运行的客户端(通常是容器)在重启后不会中断;
    * 2)在NodeManager重启并重新初始化辅助服务时，通过重新加载任何以前的状态，使辅助服务本身支持可恢复性。
* 以上描述的辅助服务的一个简单示例是`MapReduce (MR)`的辅助服务`ShuffleHandler`。
  ShuffleHandler已经遵循了上面两个要求，所以用户/管理员不需要为它做任何事情来支持NM重启:
    * 1)配置属性`mapreduce.shuffle.port`控制NodeManager主机上的ShuffleHandler绑定到哪个端口，它默认为一个非临时端口。
    * 2)ShuffleHandler服务也已经支持在NM重启后恢复以前的状态。

