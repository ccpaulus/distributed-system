# Using CGroups with YARN

CGroups 是Linux内核提供的一种可以限制单个进程或者多个进程所使用资源的机制。从YARN的角度来看，这可以限制container的资源使用。
CPU使用就是一个很好的例子。如果没有CGroups，就很难限制 container的CPU使用。当前版本，CGroups仅用于限制CPU使用。

[Linux CGroups](../../../../linux/cgroups.md)

## CGroups配置

默认情况下，`NodeManager`使用`DefaultContainerExecutor`以NodeManager启动者的身份来执行启动Container等操作，安全性低且没有任何CPU资源隔离机制。
要达到这种目的，必须要使用`LinuxContainerExecutor(LCE)`，从而以应用提交者的身份创建文件，运行/销毁 Container。
允许用户在启动Container后直接将CPU份额和进程ID写入CGroups路径的方式实现CPU资源隔离。

以下设置与设置CGroups相关。这些需要在`yarn-site.xml`中设置。

| 属性                                                                | 描述                                                                                                                                                                                                                                                                                                                                        |
|-------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.nodemanager.container-executor.class                         | 该属性应该设置为`org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor`，CGroups是Linux内核特性，通过LinuxContainerExecutor公开。                                                                                                                                                                                                                  |
| yarn.nodemanager.linux-container-executor.resources-handler.class | 该属性应该设置为`org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler`，使用LinuxContainerExecutor并不强制您使用CGroups。如果你想使用CGroups，resource-handler-class必须设置为CGroupsLCEResourceHandler。。                                                                                                                                           |
| yarn.nodemanager.linux-container-executor.cgroups.hierarchy       | 放置YARN进程的CGroups层次结构(不能包含逗号)，如果`yarn.nodemanager.linux-container-executor.cgroups.mount`为false(也就是说，如果CGroups已经预配置)，那么这个CGroups层次结构也必须配置                                                                                                                                                                                                  |
| yarn.nodemanager.linux-container-executor.cgroups.mount           | 如果没有找到，LCE是否应该尝试挂载组-可以为true或false。                                                                                                                                                                                                                                                                                                        |
| yarn.nodemanager.linux-container-executor.cgroups.mount-path      | 如果没有找到，LCE应该尝试挂载组。常见的位置包括`/sys/fs/cgroup`和`/cgroup`；默认位置取决于的Linux的发行版。<br/>该路径必须在NodeManager启动前存在。<br/>仅当LCE资源处理程序设置为`CgroupsLCEResourcesHandler`且`yarn.nodemanager.linux-container-executor.cgroups.mount`为true时才启用。<br/>这里需要注意的一点是， container执行器(`container-executor`)二进制文件将尝试挂载指定的路径+"/"+子系统。由于我们试图限制CPU，二进制文件将挂载指定的路径+"/CPU"，且路径应当存在。 |
| yarn.nodemanager.linux-container-executor.group                   | NodeManager的Unix组。它应该与`container-executor.cfg`中的设置匹配。验证 container执行器二进制文件的安全访问时需要此配置。                                                                                                                                                                                                                                                     |

以下设置与限制YARN container的资源使用有关:

| 属性                                                                      | 描述                                                                                                                                                                                                                                                       |
|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| yarn.nodemanager.resource.percentage-physical-cpu-limit                 | 这个设置允许限制所有YARN container的cpu使用率。它给所有container的CPU使用率总和设置了一个硬性上限。例如，设置为60，则所有YARN container的CPU占用率总和不会超过60%。                                                                                                                                              |
| yarn.nodemanager.linux-container-executor.cgroups.strict-resource-usage | CGroups允许container的cpu使用限制为硬限制或软限制。当此设置为true时，即使有空闲CPU可用，container也不能使用超过分配的CPU使用率，只能使用分配给它们的CPU。当设置为false时，container可以使用可用的空闲CPU。应该注意的是，无论设置为true还是false，在任何时候，所有container的CPU使用率总和都不能超过`yarn.nodemanager.resource.percentage-physical-cpu-limit`中指定的值。 |

## CGroups挂载选项

YARN通过内核(kernel)挂载到文件系统中的目录结构使用CGroups。有三个选项可以附加到CGroups

| 属性                               | 描述                                                                                                                                                                                                                            |
|----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Discover CGroups mounted already | 这应该在较新的系统上使用，比如RHEL7或Ubuntu16，或者如果管理员在YARN启动之前挂载了CGroups。设置`yarn.nodemanager.linux-container-executor.cgroups.mount`为false，并将其他配置设置为默认值。YARN将在`/proc/mounts`中找到挂载点。常见的位置包括`/sys/fs/cgroup`和`/cgroup`。默认位置根据所使用的Linux发行版而有所不同。 |
| CGroups mounted by YARN          | 重要:由于`container-executor.cfg`配置选项`feature.mount-cgroup.enabled=0`的安全原因，该选项已弃用。请在启动YARN之前挂载cgroups。                                                                                                                            |

## 安全

CGroups本身没有与安全性相关的需求。然而，LinuxContainerExecutor确实有一些要求。如果在非安全模式下运行，默认情况下，LCE以`nobody`
用户运行所有作业。
该用户可以通过设置`yarn.nodemanager.linux-container-executor.nonsecure-mode.local-user`更改为所需的用户。
但是，也可以将其配置为以`提交作业的用户`的身份运行作业。
在这种情况下，`yarn.nodemanager.linux-container-executor.nonsecure-mode.limit-users`应该设置为false。

| yarn.nodemanager.linux-container-executor.nonsecure-mode.local-user | yarn.nodemanager.linux-container-executor.nonsecure-mode.limit-users | 	User running jobs        |
|---------------------------------------------------------------------|----------------------------------------------------------------------|---------------------------|
| (default)                                                           | (default)                                                            | nobody                    |
| yarn                                                                | (default)                                                            | yarn                      |
| yarn                                                                | false                                                                | (User submitting the job) |

