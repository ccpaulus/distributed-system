# Catalogs

Catalog 提供了元数据信息，例如数据库、表、分区、视图以及数据库或其他外部系统中存储的函数和信息。

数据处理最关键的方面之一是管理元数据。 元数据可以是临时的，例如临时表、或者通过 TableEnvironment 注册的 UDF。 元数据也可以是持久化的，例如
Hive Metastore 中的元数据。Catalog 提供了一个统一的API，用于管理元数据，并使其可以从 Table API 和 SQL 查询语句中来访问。

## Catalog 类型

### GenericInMemoryCatalog

GenericInMemoryCatalog 是基于内存实现的 Catalog，所有元数据只在 session 的生命周期内可用。

### JdbcCatalog

JdbcCatalog 使得用户可以将 Flink 通过 JDBC 协议连接到关系数据库。Postgres Catalog 和 MySQL Catalog 是目前 JDBC Catalog
仅有的两种实现。 参考 [JdbcCatalog 文档]() 获取关于配置 JDBC catalog 的详细信息。

### HiveCatalog

HiveCatalog 有两个用途：作为原生 Flink 元数据的持久化存储，以及作为读写现有 Hive 元数据的接口。 Flink 的 Hive 文档 提供了有关设置
HiveCatalog 以及访问现有 Hive 元数据的详细信息。

警告 Hive Metastore 以小写形式存储所有元数据对象名称。而 GenericInMemoryCatalog 区分大小写。

### 用户自定义 Catalog

Catalog 是可扩展的，用户可以通过实现 Catalog 接口来开发自定义 Catalog。 想要在 SQL CLI 中使用自定义 Catalog，用户除了需要实现自定义的
Catalog 之外，还需要为这个 Catalog 实现对应的 CatalogFactory 接口。

CatalogFactory 定义了一组属性，用于 SQL CLI 启动时配置 Catalog。 这组属性集将传递给发现服务，在该服务中，服务会尝试将属性关联到
CatalogFactory 并初始化相应的 Catalog 实例。

从 Flink v1.16 开始, TableEnvironment 引入了一个用户类加载器，以在 table 程序、SQL Client、SQL Gateway
中保持一致的类加载行为。该类加载器会统一管理所有的用户 jar 包，包括通过 ADD JAR 或 CREATE FUNCTION .. USING JAR .. 添加的
jar 资源。 在用户自定义 catalog 中，应该将 Thread.currentThread().getContextClassLoader() 替换成该用户类加载器去加载类。否则，可能会发生
ClassNotFoundException 的异常。该用户类加载器可以通过 CatalogFactory.Context#getClassLoader 获得。

## 如何创建 Flink 表并将其注册到 Catalog

### 使用 SQL DDL

用户可以使用 DDL 通过 Table API 或者 SQL Client 在 Catalog 中创建表。

#### Java

~~~
TableEnvironment tableEnv = ...;

// Create a HiveCatalog 
Catalog catalog = new HiveCatalog("myhive", null, "<path_of_hive_conf>");

// Register the catalog
tableEnv.registerCatalog("myhive", catalog);

// Create a catalog database
tableEnv.executeSql("CREATE DATABASE mydb WITH (...)");

// Create a catalog table
tableEnv.executeSql("CREATE TABLE mytable (name STRING, age INT) WITH (...)");

tableEnv.listTables(); // should return the tables in current catalog and database.
~~~

#### SQL Client

~~~
// the catalog should have been registered via yaml file
Flink SQL> CREATE DATABASE mydb WITH (...);

Flink SQL> CREATE TABLE mytable (name STRING, age INT) WITH (...);

Flink SQL> SHOW TABLES;
mytable
~~~

更多详细信息，请参考[Flink SQL CREATE DDL]()。

### 使用 Java/Scala

用户可以用编程的方式使用Java 或者 Scala 来创建 Catalog 表。

#### Java

~~~
import org.apache.flink.table.api.*;
import org.apache.flink.table.catalog.*;
import org.apache.flink.table.catalog.hive.HiveCatalog;

TableEnvironment tableEnv = TableEnvironment.create(EnvironmentSettings.inStreamingMode());

// Create a HiveCatalog
Catalog catalog = new HiveCatalog("myhive", null, "<path_of_hive_conf>");

// Register the catalog
tableEnv.registerCatalog("myhive", catalog);

// Create a catalog database
catalog.createDatabase("mydb", new CatalogDatabaseImpl(...));

// Create a catalog table
final Schema schema = Schema.newBuilder()
    .column("name", DataTypes.STRING())
    .column("age", DataTypes.INT())
    .build();

tableEnv.createTable("myhive.mydb.mytable", TableDescriptor.forConnector("kafka")
    .schema(schema)
    // …
    .build());

List<String> tables = catalog.listTables("mydb"); // tables should contain "mytable"
~~~

## Catalog API

注意：这里只列出了编程方式的 Catalog API，用户可以使用 SQL DDL 实现许多相同的功能。 关于 DDL
的详细信息请参考 [SQL CREATE DDL]()。

### 数据库操作

~~~
// create database
catalog.createDatabase("mydb", new CatalogDatabaseImpl(...), false);

// drop database
catalog.dropDatabase("mydb", false);

// alter database
catalog.alterDatabase("mydb", new CatalogDatabaseImpl(...), false);

// get database
catalog.getDatabase("mydb");

// check if a database exist
catalog.databaseExists("mydb");

// list databases in a catalog
catalog.listDatabases("mycatalog");
~~~

### 表操作

~~~
// create table
catalog.createTable(new ObjectPath("mydb", "mytable"), new CatalogTableImpl(...), false);

// drop table
catalog.dropTable(new ObjectPath("mydb", "mytable"), false);

// alter table
catalog.alterTable(new ObjectPath("mydb", "mytable"), new CatalogTableImpl(...), false);

// rename table
catalog.renameTable(new ObjectPath("mydb", "mytable"), "my_new_table");

// get table
catalog.getTable("mytable");

// check if a table exist or not
catalog.tableExists("mytable");

// list tables in a database
catalog.listTables("mydb");
~~~

### 视图操作

~~~
// create view
catalog.createTable(new ObjectPath("mydb", "myview"), new CatalogViewImpl(...), false);

// drop view
catalog.dropTable(new ObjectPath("mydb", "myview"), false);

// alter view
catalog.alterTable(new ObjectPath("mydb", "mytable"), new CatalogViewImpl(...), false);

// rename view
catalog.renameTable(new ObjectPath("mydb", "myview"), "my_new_view", false);

// get view
catalog.getTable("myview");

// check if a view exist or not
catalog.tableExists("mytable");

// list views in a database
catalog.listViews("mydb");
~~~

### 分区操作

~~~
// create view
catalog.createPartition(
    new ObjectPath("mydb", "mytable"),
    new CatalogPartitionSpec(...),
    new CatalogPartitionImpl(...),
    false);

// drop partition
catalog.dropPartition(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...), false);

// alter partition
catalog.alterPartition(
    new ObjectPath("mydb", "mytable"),
    new CatalogPartitionSpec(...),
    new CatalogPartitionImpl(...),
    false);

// get partition
catalog.getPartition(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...));

// check if a partition exist or not
catalog.partitionExists(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...));

// list partitions of a table
catalog.listPartitions(new ObjectPath("mydb", "mytable"));

// list partitions of a table under a give partition spec
catalog.listPartitions(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...));

// list partitions of a table by expression filter
catalog.listPartitions(new ObjectPath("mydb", "mytable"), Arrays.asList(epr1, ...));
~~~

### 函数操作

~~~
// create function
catalog.createFunction(new ObjectPath("mydb", "myfunc"), new CatalogFunctionImpl(...), false);

// drop function
catalog.dropFunction(new ObjectPath("mydb", "myfunc"), false);

// alter function
catalog.alterFunction(new ObjectPath("mydb", "myfunc"), new CatalogFunctionImpl(...), false);

// get function
catalog.getFunction("myfunc");

// check if a function exist or not
catalog.functionExists("myfunc");

// list functions in a database
catalog.listFunctions("mydb");
~~~

## 通过 Table API 和 SQL Client 操作 Catalog

### 注册 Catalog

用户可以访问默认创建的内存 Catalog default_catalog，这个 Catalog 默认拥有一个默认数据库 default_database。 用户也可以注册其他的
Catalog 到现有的 Flink 会话中。

#### Java/Scala

~~~
tableEnv.registerCatalog(new CustomCatalog("myCatalog"));
~~~

#### YAML

使用 YAML 定义的 Catalog 必须提供 type 属性，以表示指定的 Catalog 类型。 以下几种类型可以直接使用。

| **Catalog**     | **Type Value**    |
|-----------------|-------------------|
| GenericInMemory | generic_in_memory |
| Hive            | hive              |

~~~
catalogs:
   - name: myCatalog
     type: custom_catalog
     hive-conf-dir: ...
~~~

### 修改当前的 Catalog 和数据库

Flink 始终在当前的 Catalog 和数据库中寻找表、视图和 UDF。

#### Java/Scala

~~~
tableEnv.useCatalog("myCatalog");
tableEnv.useDatabase("myDb");
~~~

#### SQL

~~~
Flink SQL> USE CATALOG myCatalog;
Flink SQL> USE myDB;
~~~

通过提供全限定名 catalog.database.object 来访问不在当前 Catalog 中的元数据信息。

#### Java/Scala

~~~
tableEnv.from("not_the_current_catalog.not_the_current_db.my_table");
~~~

#### SQL

~~~
Flink SQL> SELECT * FROM not_the_current_catalog.not_the_current_db.my_table;
~~~

### 列出可用的 Catalog

#### Java/Scala

~~~
tableEnv.listCatalogs();
~~~

#### SQL

~~~
Flink SQL> show catalogs;
~~~

### 列出可用的数据库

#### Java/Scala

~~~
tableEnv.listDatabases();
~~~

#### SQL

~~~
Flink SQL> show databases;
~~~

### 列出可用的表

#### Java/Scala

~~~
tableEnv.listTables();
~~~

#### SQL

~~~
Flink SQL> show tables;
~~~

