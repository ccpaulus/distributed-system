# Advanced Configuration Topics

## Anatomy of the Flink distribution

Flink本身由一组`classes`和`dependencies`组成，这些`classes`和`dependencies`构成了Flink运行时的核心，并且在启动Flink应用程序时必须出现。
这些`classes`和`dependencies`
是运行系统所需的，它们用来处理诸如`coordination`、`networking`、`checkpointing`、`failover`、`APIs`、`operators(如windowing)`
、`resource management`等领域。

这些核心`classes`和`dependencies`被打包在`flink-dist.jar`中，这个JAR在下载发行版的`/lib`目录下，也是 Flink 容器镜像的基础部分。
您可以将其近似地看作是包含 String 和 List 等公用类的 `Java 核心库`。

为了保持核心依赖`尽可能小`并`避免依赖冲突`，`Flink Core Dependencies` 不包含任何`connectors`或`库(即CEP, SQL, ML)`
，以避免在`classpath`中拥有过多默认数量的类和依赖项。

Flink 发行版的 `/lib` 目录还包含各种jar，包括常用的模块，例如 [执行 Table 作业的必需模块]() 以及一组`connector`
和`formats`。 默认情况下会自动加载，若要禁止加载只需将它们从 `classpath` 中的 `/lib` 目录中删除即可。

Flink 还在 `/opt` 目录下提供了额外的可选依赖项，可以通过移动这些 JAR 文件到 `/lib` 目录来启用这些依赖项。

有关类加载的更多细节，请查阅 [Flink 类加载]()。

## Scala Versions

不同的 Scala 版本`二进制不兼容`。所有(传递地)依赖于`Scala`的Flink依赖都以它们所构建的Scala版本为后缀(
例如:`flink-streaming-scala_2.12`)。

如果您只使用 Flink 的`Java APIs`，则可以使用任何 Scala 版本。如果您正在使用 Flink 的`Scala APIs`，则需要选择与应用程序的
Scala 匹配的 Scala 版本。

有关如何为特定的 Scala 版本构建 Flink 的详细信息，请参阅[build guide]()。

`2.12.8`之后的 Scala 版本与之前的 `2.12.x` 版本`二进制不兼容`。这使得 Flink 项目无法将其 `2.12.x` 版本直接升级到 `2.12.8`
以上。您可以按照[build guide]()在本地为更高版本的 Scala 构建Flink。为此，您需要在构建时添加 `-Djapicmp.skip` 以跳过二进制兼容性检查。

有关更多细节，请查阅 [Scala 2.12.8](https://github.com/scala/scala/releases/tag/v2.12.8) 版本说明。相关部分指出：

第二项修改是二进制不兼容的：2.12.8编译器 忽略了由 早期2.12编译器 生成的某些方法。
然而，我们相信这些方法永远不会被使用，现有的编译代码仍可工作。有关更多详细信息，请查阅[pull request 描述]()。

## Anatomy of Table Dependencies

默认情况下，Flink发行版包含执行`Flink SQL作业`所需的jar（存在与`/lib`目录中），主要有：

* flink-table-api-java-uber-1.17.0.jar → 包含所有的 Java API
* flink-table-runtime-1.17.0.jar → 包含 Table runtime
* flink-table-planner-loader-1.17.0.jar → 包含 query planner

<span style="color:orange; ">以前，这些jar都打包到`flink-table.jar`中。从`Flink 1.15`开始，已将其划分成三个 JAR，
以允许用户使用 `flink-table-planner-loader-1.17.0.jar` 充当 `flink-table-planner_2.12-1.17.0.jar`。
</span>

虽然`Table Java API artifacts`内置于发行版中，但默认情况下不包括`Table Scala API artifacts`。
在使用`Flink Scala API`的`formats`和`connectors`时，您需要手动下载这些 JAR 包并将其放到发行版的的`/lib`目录中（推荐），
或是将它们打包为`Flink SQL作业`的依赖项，加入到`uber/fat JAR`中。

有关更多详细信息，请查看[connect to external systems]()。

### Table Planner and Table Planner Loader

从Flink 1.15开始，发行版包含两个`planners`：

* `flink-table-planner_2.12-1.17.0.jar`，在`/opt`目录下，包含`query planner`
* `flink-table-planner-loader-1.17.0.jar`，默认在`/lib`中加载，包含隐藏在隔离的`classpath`后面的`query planner`(
  您将无法直接寻址任何`io.apache.flink.table.planner`)

这两个`planner JAR`包含相同的代码，但打包方式不同。在第一种情况下，您必须使用与其相同版本的 Scala。在第二种情况下，由于 Scala
已经被打包进该文件里，您不需要考虑 Scala 版本问题。

默认情况下，发行版使用`flink-table-planner-loader`。如果想使用内部`query planner`
的内部，您可以换掉 JAR 包（拷贝 `flink-table-planner_2.12.jar` 并复制到发行版的 `/lib` 目录）。
请注意，此时会被限制用于 Flink 发行版的 Scala 版本。

<span style="color:red; ">这两个`planners`不能同时存在于`classpath`中。如果您在 `/lib` 目录同时加载他们，那`Table作业`
将失败。</span>

<span style="color:orange; ">在将来的Flink版本中，我们将停止在Flink发行版中发布`flink-table-planner_2.12 artifact`。
我们强烈建议使用`API模块`来迁移`jobs`和自定义的`connectors`或`formats`，而不依赖`planner internals`。
如果您需要 `planner` 中尚未被 `API 模块`暴露的一些功能，请打开一个`ticket`以便在社区讨论。
</span>

## Hadoop Dependencies

**一般规则：** 没有必要直接添加 Hadoop 依赖到您的应用程序里，唯一的例外是您通过 [Hadoop 兼容]() 使用已有的 Hadoop 读写
format。

如果你想在 Hadoop 中使用 Flink，你需要有一个包含`Hadoop依赖项`的`Flink设置`，而不是添加 Hadoop 作为应用程序依赖项。
换句话说，Hadoop 必须是 Flink 系统本身的依赖，而不是用户代码的依赖。
Flink将使用 `HADOOP_CLASSPATH` 环境变量 指定 Hadoop 依赖项，可以这样设置：

~~~
export HADOOP_CLASSPATH=`hadoop classpath`
~~~

这种设计有两个主要原因：

* 一些`Hadoop 交互`可能在用户应用程序启动之前就发生在`Flink 内核`。
  其中包括 为`checkpoints`配置HDFS，通过Hadoop的`Kerberos令牌`进行身份验证，或者在`YARN`上部署。
* Flink 的反向类加载方式在核心依赖项中隐藏了许多传递依赖项。这不仅适用于 Flink 自己的核心依赖项，也适用于已有的 Hadoop
  依赖项。这样，应用程序就可以使用相同依赖项的不同版本，而不会遇到依赖冲突。当依赖树变得非常大时，这非常有用。

如果您在IDE中开发或测试时需要 Hadoop依赖项(例如，HDFS访问)，应该限定这些依赖项的`scope`(例如，`test`或`provided`)。

