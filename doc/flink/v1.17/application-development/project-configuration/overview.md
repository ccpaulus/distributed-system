# Project Configuration

本节中的指南将向您展示如何通过流行的构建工具(Maven, Gradle)配置项目，添加必要的依赖项(
即 [connectors and formats](connectors-and-formats.md)，[testing](test-dependencies.md))，
并涵盖一些高级配置主题（[advanced configuration topics](advanced-configuration.md)）。

每个Flink应用程序都依赖于一组`Flink库`。至少，应用程序依赖于`Flink APIs`，此外，还依赖于某些`connector库`(如Kafka,
Cassandra)，以及用户开发自定义功能来处理数据所需的`第三方依赖`。

## Getting started

要开始使用Flink应用程序，请使用以下命令、脚本和模板来创建Flink项目。

您可以使用下面的Maven命令基于prototype创建一个项目，或者使用提供的快速入门bash脚本。

<span style="color:orange; ">所有`Flink Scala APIs`都已弃用，并将在未来的Flink版本中删除。您仍然可以用`Scala`
构建应用程序。但您应该切换到`DataStream`和`Table API`的Java版本。</span>

### Maven command

您可以使用下面基于`Archetype`的`Maven命令`，或者使用提供的`quickstart`bash脚本，来创建一个项目。

~~~
$ mvn archetype:generate                \
  -DarchetypeGroupId=org.apache.flink   \
  -DarchetypeArtifactId=flink-quickstart-java \
  -DarchetypeVersion=1.17.0
~~~

这允许您命名新创建的项目，并将交互地询问您的`groupId`、`artifactId`和`package name`。

### Quickstart script

~~~
$ curl https://flink.apache.org/q/quickstart.sh | bash -s 1.17.0
~~~

[Gradle getting started 详见官网文档](https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/dev/configuration/overview/)

## Which dependencies do you need?

要开始处理Flink作业，通常需要以下依赖项：

* Flink APIs，用来开发你的作业
* [Connectors and formats]()，以将你的作业与外部系统集成
* [Testing utilities]()，以测试你的作业

除此之外，您可能还需要添加开发自定义`functions`所需的`第三方依赖项`。

### Flink APIs

Flink提供了两个主要的API:` Datastream API`和`Table API & SQL`。它们可以单独使用，也可以混合使用，这取决于您的用例：

| 想要使用的APIs                         | 需要添加的依赖项                          |
|-----------------------------------|-----------------------------------|
| DataStream                        | flink-streaming-java              |
| DataStream with Scala             | flink-streaming-scala_2.12        |
| Table API                         | flink-table-api-java              |
| Table API with Scala              | flink-table-api-scala_2.12        |
| Table API + DataStream            | flink-table-api-java-bridge       |
| Table API + DataStream with Scala | flink-table-api-scala-bridge_2.12 |

只需将它们包含在构建工具（script/descriptor）中，就可以开始开发你的job了。

## Running and packaging

如果希望通过简单地执行`main class`来运行作业，则需要在`classpath`中添加`flink-runtime`。
对于`Table API`程序，您还需要`flink-table-runtime`和`flink-table-planner-loader`。

根据经验，我们**建议**将应用程序代码及其所需的所有依赖项打包为一个`fat/uber JAR`。 这包括作业的打包`connectors`、`formats`
和`第三方依赖项`。
此规则**不适用于**`Java APIs`、`DataStream Scala APIs`和前面提到的`运行时模块`
，这些模块已经由Flink自己提供，**不应**包含在作业的`uber JAR`中。
你可以把该作业 JAR 可以提交到`已经运行的Flink集群`，也可以轻松将其添加到`Flink应用程序容器映像`中，而无需修改发行版。

## 下一步是什么？

* 要开发你的作业，请查阅 [DataStream API]() 和 [Table API & SQL]()；
* 关于如何使用特定的构建工具打包你的作业的更多细节，请查阅如下指南：
    * [Maven]()
    * [Gradle]()
* 关于项目配置的高级内容，请查阅[高级主题]()部分。

