# Dependencies for Testing

Flink提供了用于测试作业的工具类，您可以将其添加为依赖项。

## DataStream API Testing

如果要为使用`DataStream API`构建的作业开发测试，则需要添加以下依赖项：

### Maven

在项目目录中打开pom.xml文件，并在依赖项块中添加以下内容。

~~~
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-test-utils</artifactId>
    <version>1.17.0</version>
    <scope>test</scope>
</dependency>
~~~

在各种测试工具类中，该模块提供了`MiniCluster`，这是一个`轻量级的可配置Flink集群`，可在`JUnit`
测试中运行，可以`直接执行作业`。

有关如何使用这些工具类的更多信息，请参阅[DataStream API testing]()一节

## Table API Testing

如果您想在IDE中本地测试`Table API & SQL`程序，除了前面提到的`flink-test-utils`之外，还可以添加以下依赖项：

~~~
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-table-test-utils</artifactId>
    <version>1.17.0</version>
    <scope>test</scope>
</dependency>
~~~

这将自动引入`query planner`和`runtime`，它们分别用于`规划`和`执行`查询。

<span style="color:orange; ">`Flink 1.15`中开始引入`flink-table-test-utils`模块，该模块是实验性的。</span>

[Gradle Dependencies for Testing 详见官网文档](https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/dev/configuration/testing/)

