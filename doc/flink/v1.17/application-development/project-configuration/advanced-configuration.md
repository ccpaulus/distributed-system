# Advanced Configuration Topics

## Anatomy of the Flink distribution

Flink本身由一组`classes`和`dependencies`组成，这些`classes`和`dependencies`构成了Flink运行时的核心，并且在启动Flink应用程序时必须出现。
这些`classes`和`dependencies`
是运行系统所需的，它们用来处理诸如`coordination`、`networking`、`checkpointing`、`failover`、`APIs`、`operators(如windowing)`
、`resource management`等领域。

这些核心`classes`和`dependencies`被打包在`flink-dist.jar`中，这个JAR在下载发行版的`/lib`目录下，并且是基本Flink容器镜像的一部分。
您可以将这些依赖关系看作类似于`Java的核心库`，其中包含`String`和`List`等类。

为了保持核心依赖`尽可能小`并`避免依赖冲突`，Flink核心依赖不包含任何`connectors`或`库(即CEP, SQL, ML)`，以避免在`classpath`
中拥有过多默认数量的类和依赖项。

Flink发行版的`/lib`目录还包含各种jar，包括常用的模块，例如执行`Table作业`所需的所有模块以及一组`connector`和`formats`。
这些在默认情况下是加载的，并且可以从`classpath`中删除（只要把它们从`/lib`目录中移除）。

Flink还在`/opt`目录下附带了额外的可选依赖项，这些依赖可以通过移动JAR包到`/lib`目录来启用。

有关类加载的更多信息，请参阅[Classloading in Flink]()。

## Scala Versions

不同的`Scala`版本之间是`不兼容的`。所有(传递地)依赖于`Scala`的Flink依赖都以它们所构建的Scala版本为后缀(
例如:`flink-streaming-scala_2.12`)。

如果您只使用Flink的`Java APIs`，则可以使用任何Scala版本。如果您正在使用Flink的`Scala APIs`，则需要选择与应用程序的Scala版本匹配的Scala版本。

有关如何为特定的Scala版本构建Flink的详细信息，请参阅[build guide]()。

`2.12.8`之后的Scala版本与之前的`2.12.x`版本不兼容。这将阻止Flink项目在`2.12.8`之上升级`2.12.x`版本。
您可以按照[build guide]()在本地为以后的Scala版本构建Flink。为此，您需要添加`-Djapicmp.skip`，以便在构建时跳过`兼容性检查`。

请参阅[Scala 2.12.8 release notes](https://github.com/scala/scala/releases/tag/v2.12.8)了解更多细节。相关章节说明：

~~~
第二个修复是不兼容的：2.12.8编译器 忽略了由 早期2.12编译器 生成的某些方法。 然而，我们相信这些方法永远不会被使用，而已编译代码可以继续工作。
~~~

## Anatomy of Table Dependencies

默认情况下，Flink发行版包含执行`Flink SQL作业`所需的jar（存在与`/lib`目录中），特别是：

* flink-table-api-java-uber-1.17.0.jar → contains all the Java APIs
* flink-table-runtime-1.17.0.jar → contains the table runtime
* flink-table-planner-loader-1.17.0.jar → contains the query planner

<span style="color:orange; ">以前，这些jar都打包到`flink-table.jar`中。从`Flink 1.15`
开始，为了允许用户将`flink-table-planner-loader-1.17.0.jar`与`flink-table-planner_2.12-1.17.0.jar`交换，该文件现在被分成三个jar。
</span>

虽然`Table Java API artifacts`内置于发行版中，但默认情况下不包括`Table Scala API artifacts`。
在使用`Flink Scala API`的`formats`和`connectors`时，您需要下载并将这些jar包含在发行版的`/lib`目录中（推荐），
或是将它们打包为`Flink SQL作业`的依赖项，加入到`uber/fat JAR`中。

有关更多详细信息，请查看[connect to external systems]()。

### Table Planner and Table Planner Loader

从Flink 1.15开始，发行版包含两个`planners`：

* `flink-table-planner_2.12-1.17.0.jar`，在`/opt`目录下，包含`query planner`
* `flink-table-planner-loader-1.17.0.jar`，默认在`/lib`中加载，包含隐藏在隔离的`classpath`后面的`query planner`(
  您将无法直接寻址任何`io.apache.flink.table.planner`)

这两个`planner JARs`包含相同的代码，但是它们的打包不同。在第一种情况下，必须使用相同的Scala版本的JAR。在第二种情况下，您不需要考虑Scala，因为它隐藏在JAR中。

默认情况下，发行版使用`flink-table-planner-loader`。如果需要访问和使用`query planner`
的内部，可以交换jar（复制并粘贴`flink-table-planner_2.12.jar`到发行版`/lib`）。
请注意，您将被限制使用您正在使用的Flink发行版的Scala版本。

<span style="color:red; ">这两个`planners`不能同时存在于`classpath`中。如果把它们都装进`/lib`，那`Table作业`将失败。</span>

<span style="color:orange; ">在将来的Flink版本中，我们将停止在Flink发行版中发布`flink-table-planner_2.12 artifact`。
我们强烈建议使用`API模块`来迁移`jobs`和自定义的`connectors`或`formats`，而不依赖`planner internals`。
如果您需要来自`planner`的一些功能，这些功能目前没有通过`API模块`公开，请打开一个`ticket`以便在社区讨论。
</span>

## Hadoop Dependencies

**一般规则：** 没有必要将Hadoop依赖项直接添加到应用程序中。

如果你想在Hadoop中使用Flink，你需要有一个包含`Hadoop依赖项`的`Flink设置`，而不是将Hadoop作为一个应用程序依赖项添加。
换句话说，Hadoop必须依赖于`Flink系统本身`，而不是`包含应用程序的用户代码`。
Flink将使用由`HADOOP_CLASSPATH`环境变量指定的Hadoop依赖项，可以这样设置：

~~~
export HADOOP_CLASSPATH=`hadoop classpath`
~~~

这种设计有两个主要原因：

* 一些`Hadoop交互`发生在`Flink的核心`，可能在用户应用程序启动之前。其中包括为`checkpoints`
  设置HDFS，通过Hadoop的`Kerberos令牌`进行身份验证，或者部署在`YARN`上。
* Flink的反向类加载方法从核心依赖项中隐藏了许多传递依赖项。这不仅适用于Flink自己的核心依赖，也适用于安装过程中出现的Hadoop依赖。
  这样，应用程序就可以使用相同依赖项的不同版本，而不会遇到依赖冲突。当依赖树变得非常大时，这非常有用。

如果你在IDE中开发或测试时需要Hadoop依赖项(例如，HDFS访问)，您应该像配置依赖项的`scope`一样配置这些依赖项(例如，`test`
或`provided`)。

