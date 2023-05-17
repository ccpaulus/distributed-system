# Apache Hadoop YARN

## 入门

本入门部分将指导您在YARN上设置一个功能齐全的Flink集群。

### 介绍

[Apache Hadoop YARN]()是一个受许多数据处理框架欢迎的资源提供程序。Flink服务被提交给YARN的ResourceManager，它在YARN
nodemanager管理的机器上生成容器。Flink将其JobManager和TaskManager实例部署到这样的容器中。

Flink可以根据在JobManager上运行的作业所需的处理槽数动态地分配和取消分配TaskManager资源。

### 准备

本入门部分假设从`2.10.2`版本开始有一个功能良好的YARN环境。YARN环境通过Amazon EMR、Google Cloud
DataProc或Cloudera等服务提供最为方便。在本入门教程中，不建议[手动设置YARN单节点环境](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html)
或[手动设置YARN集群环境](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html)。

* 通过运行`yarn top`，确保YARN集群已准备好接受Flink应用程序。它应该不会显示任何错误消息。
* 从[下载页面]()下载最近的Flink发行版并解压缩。
* **重要事项**:确保设置了`HADOOP CLASSPATH`环境变量(可以通过运行`echo $HADOOP CLASSPATH`来检查)。如果没有，使用
    ~~~
    export HADOOP_CLASSPATH=`hadoop classpath`
    ~~~

### 在 YARN 上启动 Flink Session

一旦确保设置了`HADOOP CLASSPATH`环境变量，就可以启动一个 Flink on YARN 会话，并提交一个示例作业

~~~
# we assume to be in the root directory of 
# the unzipped Flink distribution

# (0) export HADOOP_CLASSPATH
export HADOOP_CLASSPATH=`hadoop classpath`

# (1) Start YARN Session
./bin/yarn-session.sh --detached

# (2) You can now access the Flink Web Interface through the
# URL printed in the last lines of the command output, or through
# the YARN ResourceManager web UI.

# (3) Submit example job
./bin/flink run ./examples/streaming/TopSpeedWindowing.jar

# (4) Stop YARN session (replace the application id based 
# on the output of the yarn-session.sh command)
echo "stop" | ./bin/yarn-session.sh -id application_XXXXX_XXX
~~~

恭喜你!通过在 YARN 上部署 Flink ，您已经成功运行了 Flink应用程序。

## Flink on YARN 支持的部署方式

对于生产用途，我们建议在 [Per-job or Application 模式]()下部署 Flink应用程序，因为这些模式为应用程序提供了更好的隔离。

### Application 模式

`Application 模式` 将在YARN上启动Flink集群，其中应用程序jar的main()
方法在YARN中的JobManager上执行。一旦应用程序完成，集群将立即关闭。您可以使用`yarn application -kill <ApplicationId>`
或通过取消Flink作业手动停止集群。

~~~
./bin/flink run-application -t yarn-application ./examples/streaming/TopSpeedWindowing.jar
~~~

一旦部署了 `Application 模式` 集群，您就可以与它交互，进行取消或获取保存点等操作。

~~~
# List running job on the cluster
./bin/flink list -t yarn-application -Dyarn.application.id=application_XXXX_YY
# Cancel running job
./bin/flink cancel -t yarn-application -Dyarn.application.id=application_XXXX_YY <jobId>
~~~

注意，取消 **Application 集群** 上的作业将停止 **集群**。

要充分发挥应用程序模式的潜力，请考虑将其与`yarn.provided.lib.dirs`配置选项一起使用，并将应用程序jar预上传到集群中所有节点都可以访问的位置。在本例中，命令如下所示：

~~~
./bin/flink run-application -t yarn-application \
	-Dyarn.provided.lib.dirs="hdfs://myhdfs/my-remote-flink-dist-dir" \
	hdfs://myhdfs/jars/my-application.jar
~~~

以上将使作业提交变得非常轻量级，因为所需的Flink jar和应用程序jar将由指定的远程位置提取，而不是由客户端发送到集群。

### Per-Job Cluster 模式

`Per-job Cluster`
模式将在YARN上启动Flink集群，然后在本地运行提供的应用程序jar，最后将JobGraph提交给YARN上的JobManager。如果传递`--detached`
参数，客户机将在提交被接受后停止。

YARN集群将在作业停止后停止

~~~
./bin/flink run -t yarn-per-job --detached ./examples/streaming/TopSpeedWindowing.jar
~~~

一旦部署了每个作业集群，您就可以与它交互，进行取消或获取保存点等操作。

~~~
# List running job on the cluster
./bin/flink list -t yarn-per-job -Dyarn.application.id=application_XXXX_YY
# Cancel running job
./bin/flink cancel -t yarn-per-job -Dyarn.application.id=application_XXXX_YY <jobId>
~~~

注意，取消 **Per-Job Cluster** 上的作业将停止 **集群**。

### Session 模式

我们在页面顶部的 [入门]() 指南中描述了使用 `Session 模式` 的部署。

`Session 模式` 有两种操作模式：

* `attached mode`(默认):`yarn-session.sh`客户端向YARN提交Flink集群，但客户端继续运行，跟踪集群的状态。如果集群失败，客户端将显示错误。如果客户机被终止，它也会向集群发出关闭的信号。
* `detached mode(-d or——detached)`: `yarn-session.sh`客户端将Flink集群提交给YARN，然后客户端返回。需要调用另一个客户机或YARN工具来停止Flink集群。

`Session 模式` 将在 `/tmp/.yarn-properties-<username>` 中创建一个隐藏的YARN属性文件，该文件将在提交作业时由命令行界面拾取，以便进行集群发现。

您也可以在提交Flink作业时在命令行界面中`手动指定目标YARN集群`。下面是一个例子：

~~~
./bin/flink run -t yarn-session \
  -Dyarn.application.id=application_XXXX_YY \
  ./examples/streaming/TopSpeedWindowing.jar
~~~

您可以使用以下命令`re-attach`到 YARN session ：

~~~
./bin/yarn-session.sh -id application_XXXX_YY
~~~

除了在`conf/flink-conf.yaml`文件进行[配置]()，您还可以使用`-Dkey=value`
参数，在提交时将任何配置传递给`./bin/yarn-session.sh`客户端。

YARN session 客户端也有一些常用设置的快捷参数。这些快捷参数可以使用`./bin/yarn-session.sh -h`展示出来。

## Flink on YARN 参考

### 配置 Flink on YARN

在 [配置页面]() 中列出了与 YARN 相关的配置。

以下配置参数由 `Flink on YARN` 管理，因为它们可能在运行时被框架覆盖：

* `jobmanager.rpc.address`(通过 `Flink on YARN` 动态设置 JobManager 容器的地址)
* `io.tmp.dirs`(如果没有设置，Flink 将其设置为 YARN 定义的临时目录)
* `high-availability.cluster-id`(自动生成的ID，用于区分高可用服务中的多个集群)

如果您有需要，您可以通过设置 `HADOOP_CONF_DIR`
环境变量，来将额外的Hadoop配置文件传递给Flink，它接受包含Hadoop配置文件的 `目录名`
。默认情况下，所有必需的Hadoop配置文件都是通过`HADOOP_CLASSPATH`环境变量从`classpath`加载的。

### 资源分配行为

运行在 YARN 上的 JobManager 如果不能使用现有资源运行所有提交的作业，将会请求额外的 TaskManagers。特别是在 `Session 模式`
下运行时，如果需要，JobManager 会在提交`额外作业`时分配额外的 TaskManagers。未使用的 TaskManagers 将在超时后再次释放。

`YARN 实现` 将尊重 JobManager 和 TaskManager 进程的内存配置。默认情况下，上报的 vcore 数等于每个 TaskManager 配置的 slots
数。`yarn.containers.vcores`允许使用自定义值覆盖 vcore 的数量。为了使这个参数生效，您应该在YARN集群中启用CPU调度。

YARN 会替换失败的容器(包括 JobManager )。 JobManager 容器重启的最大次数是通过` yarn.application-attempts`(默认为1)
。一旦所有尝试都用尽，YARN应用程序将失败。

### 基于 YARN 的高可用

`基于 YARN 的高可用` 是通过 YARN 和 [高可用性服务]() 的组合来实现的。

一旦配置了HA服务，它将持久化 `JobManager 元数据` 并执行 `leader选举`。

YARN 负责重新启动`失败的 JobManagers`。通过两个配置参数定义 JobManager 重启的最大次数。首先是 Flink
的`yarn.application-attempts`配置，默认为2（HA时）。该值受 YARN 的`yarn.resourcemanager.am.max-attempts`的限制，默认值也为2。

请注意， 在YARN上部署时，Flink 将管理 `high-availability.cluster-id`配置参数。Flink 将它默认设置为`YARN application id`。
<span style="color:orange;">在YARN上部署HA集群时，不应覆盖此参数。</span>
`集群ID`用于区分`HA后端(例如Zookeeper)`的`多个HA集群`。覆盖此配置参数会导致多个YARN集群相互影响。

#### 容器关闭行为

* `YARN 2.3.0 < version < 2.4.0`：如果`AM(application master)`失败，将重新启动所有容器。
* `YARN 2.4.0 < version < 2.6.0`：`TaskManager 容器` 在`AM(application master)`故障期间保持活动状态。这样做的好处是启动时间更快，并且用户不必等待再次获得容器资源。
* `YARN 2.6.0 <= version`：将`尝试失败有效间隔`设置为`Flinks’ Akka`的`超时(timeout)`值。`尝试失败有效间隔`
  表示，只有当系统在一个`间隔内`看到应用程序的`最大尝试次数`后，应用程序才会被杀死

<span style="color:red; ">`Hadoop YARN 2.4.0`有一个主要错误(已在2.5.0中修复)
，该错误会阻止`重启后的AM(application master)或JobManager`重启容器。详见[FLINK-4142]()。我们建议至少使用`Hadoop 2.5.0`
在YARN上进行高可用性设置。</span>

<blockquote style="">
  Hadoop YARN 2.4.0 有一个主要错误(已在2.5.0中修复)，该错误会阻止 重启后的AM(application master) 或 JobManager 重启容器。详见[FLINK-4142]()。我们建议至少使用 Hadoop 2.5.0 在YARN上进行高可用性设置。
</blockquote>

### 支持的 Hadoop 版本

`Flink on YARN`是基于`Hadoop 2.10.2`编译的，支持所有`大于等于2.10.2`的Hadoop版本，包括`Hadoop 3.x`。

为了向 Flink 提供所需的 Hadoop 依赖项，我们建议设置`HADOOP_CLASSPATH`环境变量。

如果做不到，也可以将依赖项放入 Flink 的 `lib/` 目录。

Flink also offers pre-bundled Hadoop fat jars for placing them in the lib/ folder, on
the [Downloads / Additional Components]() section of the website. These pre-bundled fat jars are shaded to avoid
dependency conflicts with common libraries. The Flink community is not testing the YARN integration against these
pre-bundled jars.

### 在防火墙后运行 Flink on YARN

一些 YARN 集群会使用`防火墙`来控制`集群`和`网络其他部分`之间的网络流量。在这些设置中，只能从`集群网络内(在防火墙后面)`
将 `Flink作业` 提交给 `YARN session`。如果这对于生产环境是不可行的，Flink 允许为其`REST endpoint`
配置端口范围，用于`客户机-集群`通信。配置了端口范围后，用户还可以越过防火墙向Flink提交作业。

指定`REST endpoint`端口的配置参数为`rest.bind-port`。此配置选项接受 单个端口(例如:50010)、范围(50000-50025) 或 两者的组合。

### 用户的 jars 和 Classpath

#### Session 模式

当在 Yarn 上以 `Session 模式` 部署 Flink 时，只有在启动命令中指定的`JAR文件`才会被识别为`user-jars`
并包含到`用户 classpath`中。

#### PerJob 模式 & Application 模式

当在 Yarn 上以 `PerJob 模式 或 Application 模式` 部署 Flink 时，在启动命令中指定的`JAR文件`和 Flink 的`usrlib 文件夹`
中的`所有JAR文件`将被识别为`user-jars`。默认情况下，Flink 将把` user-jars`包含到`system classpath`
中。这种行为可以通过`yarn.classpath.include-user-jar`参数控制。

而当其设置为`DISABLED`时，Flink 将在`user classpath`中包含jar。

可以通过将参数设置为以下值，来控制`user-jars`在`classpath`中的位置：

* `ORDER(默认)`：根据字母顺序，将jar添加到`system classpath`中。
* `FIRST`：将jar添加到`system classpath`的开头。
* `LAST`：将jar添加到`system classpath`的末尾。

详细信息请参考[调试类加载文档]()。

