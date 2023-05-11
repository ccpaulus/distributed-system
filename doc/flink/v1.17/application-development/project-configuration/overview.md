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

* Flink APIs，以开发您的job
* Connectors and formats，以便将您的job与外部系统集成
* Testing utilities，为了测试你的job

除此之外，您可能还需要添加开发自定义`functions`所需的`第三方依赖项`。

### Flink APIs

## Running and packaging

## What’s next?
