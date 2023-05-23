# Connectors and Formats

Flink应用程序可以通过`connectors`读取和写入各种外部系统。它支持多种`格式（formats）`，以便对数据进行`编码`和`解码`
以匹配Flink的`数据结构`。

`DataStream`和`Table API/SQL`两者都提供了可用`connectors`和`formats`的概述。

## Available artifacts

为了使用`connectors`和`formats`，您需要确保Flink能够访问实现它们的`artifacts`。
对于Flink社区支持的每个`connector`，我们都会在`Maven Central`上发布两个`artifacts`：

* `flink-connector-<NAME>`是一个`thin JAR`，只包含`connector`代码，但不包括最终的第三方依赖项
* `flink-sql-connector-<NAME>`是一个`uber JAR`，包含所有`connector`第三方依赖项一起使用

这同样适用于`formats`。注意，一些`connectors`可能没有相应的`flink-sql-connector-<NAME> artifact`，因为它们不需要第三方依赖项。

<span style="color:orange; ">支持`uber/fat JARs`主要是为了与`SQL client`一起使用，但您也可以在`DataStream/Table`
应用程序中使用它们。</span>

## Using artifacts

为了使用`connector`或`format`模块，您可以：

* Shade `thin JAR` and its transitive dependencies
* Shade the `uber JAR` in your job JAR
* Copy the uber JAR directly in the `/lib` folder of the Flink distribution

决定是打成 `uber JAR`、`thin JAR`，还是仅仅`在发行版中包含依赖`取决于您和您的使用场景。
如果您使用 `uber JAR`，您将对`作业JAR`中的依赖项版本有更多的控制。
如果您使用 `thin JAR`，您将对传递依赖项有更多的控制，因为您可以在不更改`connector`版本的情况下更改版本(允许二进制兼容)。
如果直接在Flink发行版 `/lib` 目录里嵌入`connector uber JAR`，您将能够在一个地方统一控制`所有作业`的`connector`版本。

