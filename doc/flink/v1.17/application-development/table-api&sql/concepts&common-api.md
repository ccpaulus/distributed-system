# 概念与通用 API

Table API 和 SQL 集成在同一套 API 中。 这套 API 的核心概念是Table，用作查询的输入和输出。 本文介绍 Table API 和 SQL
查询程序的通用结构、如何注册 Table 、如何查询 Table 以及如何输出 Table 。

## Table API 和 SQL 程序的结构

所有用于批处理和流处理的 Table API 和 SQL 程序都遵循相同的模式。下面的代码示例展示了 Table API 和 SQL 程序的通用结构。

All Flink Scala APIs are deprecated and will be removed in a future Flink version. You can still build your application
in Scala, but you should move to the Java version of either the DataStream and/or Table API.

See [FLIP-265 Deprecate and remove Scala API support]()

~~~
import org.apache.flink.table.api.*;
import org.apache.flink.connector.datagen.table.DataGenConnectorOptions;

// Create a TableEnvironment for batch or streaming execution.
// See the "Create a TableEnvironment" section for details.
TableEnvironment tableEnv = TableEnvironment.create(/*…*/);

// Create a source table
tableEnv.createTemporaryTable("SourceTable", TableDescriptor.forConnector("datagen")
    .schema(Schema.newBuilder()
      .column("f0", DataTypes.STRING())
      .build())
    .option(DataGenConnectorOptions.ROWS_PER_SECOND, 100L)
    .build());

// Create a sink table (using SQL DDL)
tableEnv.executeSql("CREATE TEMPORARY TABLE SinkTable WITH ('connector' = 'blackhole') LIKE SourceTable (EXCLUDING OPTIONS) ");

// Create a Table object from a Table API query
Table table1 = tableEnv.from("SourceTable");

// Create a Table object from a SQL query
Table table2 = tableEnv.sqlQuery("SELECT * FROM SourceTable");

// Emit a Table API result Table to a TableSink, same for SQL result
TableResult tableResult = table1.insertInto("SinkTable").execute();
~~~

注意： Table API 和 SQL 查询可以很容易地集成并嵌入到 DataStream 程序中。 请参阅[与 DataStream API 集成]() 章节了解如何将
DataStream 与表之间的相互转化。

## 创建 TableEnvironment

TableEnvironment 是 Table API 和 SQL 的核心概念。它负责:

* 在内部的 catalog 中注册 Table
* 注册外部的 catalog
* 加载可插拔模块
* 执行 SQL 查询
* 注册自定义函数 （scalar、table 或 aggregation）
* DataStream 和 Table 之间的转换(面向 StreamTableEnvironment )

Table 总是与特定的 TableEnvironment 绑定。 不能在同一条查询中使用不同 TableEnvironment 中的表，例如，对它们进行 join 或
union 操作。 TableEnvironment 可以通过静态方法 TableEnvironment.create() 创建。

~~~
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.TableEnvironment;

EnvironmentSettings settings = EnvironmentSettings
    .newInstance()
    .inStreamingMode()
    //.inBatchMode()
    .build();

TableEnvironment tEnv = TableEnvironment.create(settings);
~~~

或者，用户可以从现有的 StreamExecutionEnvironment 创建一个 StreamTableEnvironment 与 DataStream API 互操作。

~~~
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
StreamTableEnvironment tEnv = StreamTableEnvironment.create(env);
~~~

## 在 Catalog 中创建表

TableEnvironment 维护着一个由标识符（identifier）创建的表 catalog 的映射。标识符由三个部分组成：catalog 名称、数据库名称以及对象名称。如果
catalog 或者数据库没有指明，就会使用当前默认值（参见[表标识符扩展]()章节中的例子）。

Table 可以是虚拟的（视图 VIEWS）也可以是常规的（表 TABLES）。视图 VIEWS可以从已经存在的Table中创建，一般是 Table API 或者 SQL
的查询结果。 表TABLES描述的是外部数据，例如文件、数据库表或者消息队列。

### 临时表（Temporary Table）和永久表（Permanent Table）

表可以是临时的，并与单个 Flink 会话（session）的生命周期相关，也可以是永久的，并且在多个 Flink 会话和群集（cluster）中可见。

永久表需要 [catalog]()（例如 Hive Metastore）以维护表的元数据。一旦永久表被创建，它将对任何连接到 catalog 的 Flink
会话可见且持续存在，直至被明确删除。

另一方面，临时表通常保存于内存中并且仅在创建它们的 Flink 会话持续期间存在。这些表对于其它会话是不可见的。它们不与任何
catalog 或者数据库绑定但可以在一个命名空间（namespace）中创建。即使它们对应的数据库被删除，临时表也不会被删除。

#### 屏蔽（Shadowing）

可以使用与已存在的永久表相同的标识符去注册临时表。临时表会屏蔽永久表，并且只要临时表存在，永久表就无法访问。所有使用该标识符的查询都将作用于临时表。

这可能对实验（experimentation）有用。它允许先对一个临时表进行完全相同的查询，例如只有一个子集的数据，或者数据是不确定的。一旦验证了查询的正确性，就可以对实际的生产表进行查询。

### 创建表

虚拟表 #
在 SQL 的术语中，Table API 的对象对应于视图（虚拟表）。它封装了一个逻辑查询计划。它可以通过以下方法在 catalog 中创建：

~~~
// get a TableEnvironment
TableEnvironment tableEnv = ...; // see "Create a TableEnvironment" section

// table is the result of a simple projection query 
Table projTable = tableEnv.from("X").select(...);

// register the Table projTable as table "projectedTable"
tableEnv.createTemporaryView("projectedTable", projTable);
~~~

**注意：** 从传统数据库系统的角度来看，Table 对象与 VIEW 视图非常像。也就是，定义了 Table 的查询是没有被优化的，
而且会被内嵌到另一个引用了这个注册了的 Table的查询中。如果多个查询都引用了同一个注册了的Table，那么它会被内嵌每个查询中并被执行多次，
也就是说注册了的Table的结果**不会**被共享。

#### Connector Tables

另外一个方式去创建 TABLE 是通过 [connector]() 声明。Connector 描述了存储表数据的外部系统。存储系统例如 Apache Kafka
或者常规的文件系统都可以通过这种方式来声明。

Such tables can either be created using the Table API directly, or by switching to SQL DDL.

~~~
// Using table descriptors
final TableDescriptor sourceDescriptor = TableDescriptor.forConnector("datagen")
    .schema(Schema.newBuilder()
    .column("f0", DataTypes.STRING())
    .build())
    .option(DataGenConnectorOptions.ROWS_PER_SECOND, 100L)
    .build();

tableEnv.createTable("SourceTableA", sourceDescriptor);
tableEnv.createTemporaryTable("SourceTableB", sourceDescriptor);

// Using SQL DDL
tableEnv.executeSql("CREATE [TEMPORARY] TABLE MyTable (...) WITH (...)");
~~~

### 扩展表标识符

表总是通过三元标识符注册，包括 catalog 名、数据库名和表名。

用户可以指定一个 catalog 和数据库作为 “当前catalog” 和"当前数据库"。有了这些，那么刚刚提到的三元标识符的前两个部分就可以被省略了。如果前两部分的标识符没有指定，
那么会使用当前的 catalog 和当前数据库。用户也可以通过 Table API 或 SQL 切换当前的 catalog 和当前的数据库。

标识符遵循 SQL 标准，因此使用时需要用反引号（`）进行转义。

~~~
TableEnvironment tEnv = ...;
tEnv.useCatalog("custom_catalog");
tEnv.useDatabase("custom_database");

Table table = ...;

// register the view named 'exampleView' in the catalog named 'custom_catalog'
// in the database named 'custom_database' 
tableEnv.createTemporaryView("exampleView", table);

// register the view named 'exampleView' in the catalog named 'custom_catalog'
// in the database named 'other_database' 
tableEnv.createTemporaryView("other_database.exampleView", table);

// register the view named 'example.View' in the catalog named 'custom_catalog'
// in the database named 'custom_database' 
tableEnv.createTemporaryView("`example.View`", table);

// register the view named 'exampleView' in the catalog named 'other_catalog'
// in the database named 'other_database' 
tableEnv.createTemporaryView("other_catalog.other_database.exampleView", table);
~~~

## 查询表

### Table API

Table API 是关于 Scala 和 Java 的集成语言式查询 API。与 SQL 相反，Table API 的查询不是由字符串指定，而是在宿主语言中逐步构建。

Table API 是基于 Table 类的，该类表示一个表（流或批处理），并提供使用关系操作的方法。这些方法返回一个新的 Table 对象，该对象表示对输入
Table 进行关系操作的结果。 一些关系操作由多个方法调用组成，例如 table.groupBy(...).select()，其中 groupBy(...) 指定 table
的分组，而 select(...) 在 table 分组上的投影。

文档 [Table API]() 说明了所有流处理和批处理表支持的 Table API 算子。

以下示例展示了一个简单的 Table API 聚合查询：

~~~
// get a TableEnvironment
TableEnvironment tableEnv = ...; // see "Create a TableEnvironment" section

// register Orders table

// scan registered Orders table
Table orders = tableEnv.from("Orders");
// compute revenue for all customers from France
Table revenue = orders
  .filter($("cCountry").isEqual("FRANCE"))
  .groupBy($("cID"), $("cName"))
  .select($("cID"), $("cName"), $("revenue").sum().as("revSum"));

// emit or convert Table
// execute query
~~~

### SQL

Flink SQL 是基于实现了SQL标准的 Apache Calcite 的。SQL 查询由常规字符串指定。

文档 [SQL]() 描述了Flink对流处理和批处理表的SQL支持。

下面的示例演示了如何指定查询并将结果作为 Table 对象返回。

~~~
// get a TableEnvironment
TableEnvironment tableEnv = ...; // see "Create a TableEnvironment" section

// register Orders table

// compute revenue for all customers from France
Table revenue = tableEnv.sqlQuery(
    "SELECT cID, cName, SUM(revenue) AS revSum " +
    "FROM Orders " +
    "WHERE cCountry = 'FRANCE' " +
    "GROUP BY cID, cName"
  );

// emit or convert Table
// execute query
~~~

如下的示例展示了如何指定一个更新查询，将查询的结果插入到已注册的表中。

~~~
// get a TableEnvironment
TableEnvironment tableEnv = ...; // see "Create a TableEnvironment" section

// register "Orders" table
// register "RevenueFrance" output table

// compute revenue for all customers from France and emit to "RevenueFrance"
tableEnv.executeSql(
    "INSERT INTO RevenueFrance " +
    "SELECT cID, cName, SUM(revenue) AS revSum " +
    "FROM Orders " +
    "WHERE cCountry = 'FRANCE' " +
    "GROUP BY cID, cName"
  );
~~~

### 混用 Table API 和 SQL

Table API 和 SQL 查询的混用非常简单因为它们都返回 Table 对象：

可以在 SQL 查询返回的 Table 对象上定义 Table API 查询。
在 TableEnvironment 中注册的[结果表]()可以在 SQL 查询的 FROM 子句中引用，通过这种方法就可以在 Table API 查询的结果上定义
SQL 查询。
Back to top

## 输出表

Table 通过写入 TableSink 输出。TableSink 是一个通用接口，用于支持多种文件格式（如 CSV、Apache Parquet、Apache Avro）、存储系统（如
JDBC、Apache HBase、Apache Cassandra、Elasticsearch）或消息队列系统（如 Apache Kafka、RabbitMQ）。

批处理 Table 只能写入 BatchTableSink，而流处理 Table 需要指定写入 AppendStreamTableSink，RetractStreamTableSink 或者
UpsertStreamTableSink。

请参考文档 [Table Sources & Sinks]() 以获取更多关于可用 Sink 的信息以及如何自定义 DynamicTableSink。

方法 Table.insertInto(String tableName) 定义了一个完整的端到端管道将源表中的数据传输到一个被注册的输出表中。 该方法通过名称在
catalog 中查找输出表并确认 Table schema 和输出表 schema 一致。 可以通过方法 TablePipeline.explain() 和
TablePipeline.execute() 分别来解释和执行一个数据流管道。

下面的示例演示如何输出 Table：

~~~
// get a TableEnvironment
TableEnvironment tableEnv = ...; // see "Create a TableEnvironment" section

// create an output Table
final Schema schema = Schema.newBuilder()
    .column("a", DataTypes.INT())
    .column("b", DataTypes.STRING())
    .column("c", DataTypes.BIGINT())
    .build();

tableEnv.createTemporaryTable("CsvSinkTable", TableDescriptor.forConnector("filesystem")
    .schema(schema)
    .option("path", "/path/to/file")
    .format(FormatDescriptor.forFormat("csv")
        .option("field-delimiter", "|")
        .build())
    .build());

// compute a result Table using Table API operators and/or SQL queries
Table result = ...;

// Prepare the insert into pipeline
TablePipeline pipeline = result.insertInto("CsvSinkTable");

// Print explain details
pipeline.printExplain();

// emit the result Table to the registered TableSink
pipeline.execute();
~~~

## 翻译与执行查询

不论输入数据源是流式的还是批式的，Table API 和 SQL 查询都会被转换成 [DataStream]() 程序。 查询在内部表示为逻辑查询计划，并被翻译成两个阶段：

1. 优化逻辑执行计划
2. 翻译成 DataStream 程序

Table API 或者 SQL 查询在下列情况下会被翻译：

* 当 TableEnvironment.executeSql() 被调用时。该方法是用来执行一个 SQL 语句，一旦该方法被调用， SQL 语句立即被翻译。
* 当 TablePipeline.execute() 被调用时。该方法是用来执行一个源表到输出表的数据流，一旦该方法被调用， TABLE API 程序立即被翻译。
* 当 Table.execute() 被调用时。该方法是用来将一个表的内容收集到本地，一旦该方法被调用， TABLE API 程序立即被翻译。
* 当 StatementSet.execute() 被调用时。TablePipeline （通过 StatementSet.add() 输出给某个 Sink）和 INSERT 语句 （通过调用
  StatementSet.addInsertSql()）会先被缓存到 StatementSet 中，StatementSet.execute() 方法被调用时，所有的 sink 会被优化成一张有向无环图。
* 当 Table 被转换成 DataStream 时（参阅与 [DataStream 集成]()）。转换完成后，它就成为一个普通的 DataStream 程序，并会在调用
  StreamExecutionEnvironment.execute() 时被执行。

## 查询优化

Apache Flink 使用并扩展了 Apache Calcite 来执行复杂的查询优化。 这包括一系列基于规则和成本的优化，例如：

* 基于 Apache Calcite 的子查询解相关
* 投影剪裁
* 分区剪裁
* 过滤器下推
* 子计划消除重复数据以避免重复计算
* 特殊子查询重写，包括两部分：
    * 将 IN 和 EXISTS 转换为 left semi-joins
    * 将 NOT IN 和 NOT EXISTS 转换为 left anti-join
* 可选 join 重新排序
    * 通过 table.optimizer.join-reorder-enabled 启用

**注意：** 当前仅在子查询重写的结合条件下支持 IN / EXISTS / NOT IN / NOT EXISTS。

优化器不仅基于计划，而且还基于可从数据源获得的丰富统计信息以及每个算子（例如 io，cpu，网络和内存）的细粒度成本来做出明智的决策。

高级用户可以通过 CalciteConfig 对象提供自定义优化，可以通过调用 TableEnvironment＃getConfig＃setPlannerConfig 将其提供给
TableEnvironment。

## 解释表

Table API 提供了一种机制来解释计算 Table 的逻辑和优化查询计划。 这是通过 Table.explain() 方法或者 StatementSet.explain()
方法来完成的。Table.explain() 返回一个 Table 的计划。StatementSet.explain() 返回多 sink 计划的结果。它返回一个描述三种计划的字符串：

1. 关系查询的抽象语法树（the Abstract Syntax Tree），即未优化的逻辑查询计划，
2. 优化的逻辑查询计划，以及
3. 物理执行计划。

可以用 TableEnvironment.explainSql() 方法和 TableEnvironment.executeSql() 方法支持执行一个 EXPLAIN
语句获取逻辑和优化查询计划，请参阅 [EXPLAIN]() 页面.

以下代码展示了一个示例以及对给定 Table 使用 Table.explain() 方法的相应输出：

~~~
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
StreamTableEnvironment tEnv = StreamTableEnvironment.create(env);

DataStream<Tuple2<Integer, String>> stream1 = env.fromElements(new Tuple2<>(1, "hello"));
DataStream<Tuple2<Integer, String>> stream2 = env.fromElements(new Tuple2<>(1, "hello"));

// explain Table API
Table table1 = tEnv.fromDataStream(stream1, $("count"), $("word"));
Table table2 = tEnv.fromDataStream(stream2, $("count"), $("word"));
Table table = table1
  .where($("word").like("F%"))
  .unionAll(table2);

System.out.println(table.explain());
~~~

上述例子的结果是：

~~~
== Abstract Syntax Tree ==
LogicalUnion(all=[true])
:- LogicalFilter(condition=[LIKE($1, _UTF-16LE'F%')])
:  +- LogicalTableScan(table=[[Unregistered_DataStream_1]])
+- LogicalTableScan(table=[[Unregistered_DataStream_2]])

== Optimized Physical Plan ==
Union(all=[true], union=[count, word])
:- Calc(select=[count, word], where=[LIKE(word, _UTF-16LE'F%')])
:  +- DataStreamScan(table=[[Unregistered_DataStream_1]], fields=[count, word])
+- DataStreamScan(table=[[Unregistered_DataStream_2]], fields=[count, word])

== Optimized Execution Plan ==
Union(all=[true], union=[count, word])
:- Calc(select=[count, word], where=[LIKE(word, _UTF-16LE'F%')])
:  +- DataStreamScan(table=[[Unregistered_DataStream_1]], fields=[count, word])
+- DataStreamScan(table=[[Unregistered_DataStream_2]], fields=[count, word])
~~~

以下代码展示了一个示例以及使用 StatementSet.explain() 的多 sink 计划的相应输出：

~~~
EnvironmentSettings settings = EnvironmentSettings.inStreamingMode();
TableEnvironment tEnv = TableEnvironment.create(settings);

final Schema schema = Schema.newBuilder()
    .column("count", DataTypes.INT())
    .column("word", DataTypes.STRING())
    .build();

tEnv.createTemporaryTable("MySource1", TableDescriptor.forConnector("filesystem")
    .schema(schema)
    .option("path", "/source/path1")
    .format("csv")
    .build());
tEnv.createTemporaryTable("MySource2", TableDescriptor.forConnector("filesystem")
    .schema(schema)
    .option("path", "/source/path2")
    .format("csv")
    .build());
tEnv.createTemporaryTable("MySink1", TableDescriptor.forConnector("filesystem")
    .schema(schema)
    .option("path", "/sink/path1")
    .format("csv")
    .build());
tEnv.createTemporaryTable("MySink2", TableDescriptor.forConnector("filesystem")
    .schema(schema)
    .option("path", "/sink/path2")
    .format("csv")
    .build());

StatementSet stmtSet = tEnv.createStatementSet();

Table table1 = tEnv.from("MySource1").where($("word").like("F%"));
stmtSet.add(table1.insertInto("MySink1"));

Table table2 = table1.unionAll(tEnv.from("MySource2"));
stmtSet.add(table2.insertInto("MySink2"));

String explanation = stmtSet.explain();
System.out.println(explanation);
~~~

多 sink 计划的结果是：

~~~
== Abstract Syntax Tree ==
LogicalLegacySink(name=[`default_catalog`.`default_database`.`MySink1`], fields=[count, word])
+- LogicalFilter(condition=[LIKE($1, _UTF-16LE'F%')])
   +- LogicalTableScan(table=[[default_catalog, default_database, MySource1, source: [CsvTableSource(read fields: count, word)]]])

LogicalLegacySink(name=[`default_catalog`.`default_database`.`MySink2`], fields=[count, word])
+- LogicalUnion(all=[true])
:- LogicalFilter(condition=[LIKE($1, _UTF-16LE'F%')])
:  +- LogicalTableScan(table=[[default_catalog, default_database, MySource1, source: [CsvTableSource(read fields: count, word)]]])
+- LogicalTableScan(table=[[default_catalog, default_database, MySource2, source: [CsvTableSource(read fields: count, word)]]])

== Optimized Physical Plan ==
LegacySink(name=[`default_catalog`.`default_database`.`MySink1`], fields=[count, word])
+- Calc(select=[count, word], where=[LIKE(word, _UTF-16LE'F%')])
+- LegacyTableSourceScan(table=[[default_catalog, default_database, MySource1, source: [CsvTableSource(read fields: count, word)]]], fields=[count, word])

LegacySink(name=[`default_catalog`.`default_database`.`MySink2`], fields=[count, word])
+- Union(all=[true], union=[count, word])
:- Calc(select=[count, word], where=[LIKE(word, _UTF-16LE'F%')])
:  +- LegacyTableSourceScan(table=[[default_catalog, default_database, MySource1, source: [CsvTableSource(read fields: count, word)]]], fields=[count, word])
+- LegacyTableSourceScan(table=[[default_catalog, default_database, MySource2, source: [CsvTableSource(read fields: count, word)]]], fields=[count, word])

== Optimized Execution Plan ==
Calc(select=[count, word], where=[LIKE(word, _UTF-16LE'F%')])(reuse_id=[1])
+- LegacyTableSourceScan(table=[[default_catalog, default_database, MySource1, source: [CsvTableSource(read fields: count, word)]]], fields=[count, word])

LegacySink(name=[`default_catalog`.`default_database`.`MySink1`], fields=[count, word])
+- Reused(reference_id=[1])

LegacySink(name=[`default_catalog`.`default_database`.`MySink2`], fields=[count, word])
+- Union(all=[true], union=[count, word])
:- Reused(reference_id=[1])
+- LegacyTableSourceScan(table=[[default_catalog, default_database, MySource2, source: [CsvTableSource(read fields: count, word)]]], fields=[count, word])
~~~