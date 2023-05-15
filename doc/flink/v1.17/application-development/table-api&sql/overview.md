# Table API & SQL

Apache Flink 有两种关系型 API 来做流批统一处理：Table API 和 SQL。Table API 是用于 Scala 和 Java
语言的查询API，它可以用一种非常直观的方式来组合使用选取、过滤、join 等关系型算子。Flink SQL 是基于[ Apache Calcite]() 来实现的标准
SQL。无论输入是连续的（流式）还是有界的（批处理），在两个接口中指定的查询都具有相同的语义，并指定相同的结果。

Table API 和 SQL 两种 API 是紧密集成的，以及 DataStream API。你可以在这些 API 之间，以及一些基于这些 API 的库之间轻松的切换。
For instance, you can detect patterns from a table using [MATCH_RECOGNIZE clause]() and later use the DataStream API to
build alerting based on the matched patterns.

## Table 程序依赖

您需要将 Table API 作为依赖项添加到项目中，以便用 Table API 和 SQL 定义数据管道。

有关如何为 Java 和 Scala 配置这些依赖项的更多细节，请查阅[项目配置]()小节。

如果您使用 Python，请查阅 [Python API]() 文档。

## 接下来？

* [公共概念和 API](): Table API 和 SQL 公共概念以及 API。
* [数据类型](): 内置数据类型以及它们的属性
* [流式概念](): Table API 和 SQL 中流式相关的文档，比如配置时间属性和如何处理更新结果。
* [连接外部系统](): 读写外部系统的连接器和格式。
* [Table API](): Table API 支持的操作。
* [SQL](): SQL 支持的操作和语法。
* [内置函数](): Table API 和 SQL 中的内置函数。
* [SQL Client](): 不用编写代码就可以尝试 Flink SQL，可以直接提交 SQL 任务到集群上。

