# Table API

Table API 是批处理和流处理的统一的关系型 API。Table API 的查询不需要修改代码就可以采用批输入或流输入来运行。Table API 是
SQL 语言的超集，并且是针对 Apache Flink 专门设计的。Table API 集成了 Scala，Java 和 Python 语言的 API。Table API 的查询是使用
Java，Scala 或 Python 语言嵌入的风格定义的，有诸如自动补全和语法校验的 IDE 支持，而不是像普通 SQL 一样使用字符串类型的值来指定查询。

Table API 和 Flink SQL 共享许多概念以及部分集成的 API。通过查看[公共概念 & API]()
来学习如何注册表或如何创建一个表对象。[流概念]()页面讨论了诸如动态表和时间属性等流特有的概念。

下面的例子中假定有一张叫 Orders 的表，表中有属性 (a, b, c, rowtime) 。rowtime 字段是流任务中的逻辑[时间属性]()
或是批任务中的普通时间戳字段。

## 概述 & 示例

Table API 支持 Scala, Java 和 Python 语言。Scala 语言的 Table API 利用了 Scala 表达式，Java 语言的 Table API 支持 DSL
表达式和解析并转换为等价表达式的字符串，Python 语言的 Table API 仅支持解析并转换为等价表达式的字符串。

下面的例子展示了 Scala、Java 和 Python 语言的 Table API 的不同之处。表程序是在批环境下执行的。程序扫描了 Orders 表，通过字段
a 进行分组，并计算了每组结果的行数。

Java 的 Table API 通过引入 org.apache.flink.table.api.java.* 来使用。下面的例子展示了如何创建一个 Java 的 Table API
程序，以及表达式是如何指定为字符串的。 使用DSL表达式时也需要引入静态的 org.apache.flink.table.api.Expressions.*。

~~~
import org.apache.flink.table.api.*;

import static org.apache.flink.table.api.Expressions.*;

EnvironmentSettings settings = EnvironmentSettings
    .newInstance()
    .inStreamingMode()
    .build();

TableEnvironment tEnv = TableEnvironment.create(settings);

// 在表环境中注册 Orders 表
// ...

// 指定表程序
Table orders = tEnv.from("Orders"); // schema (a, b, c, rowtime)

Table counts = orders
        .groupBy($("a"))
        .select($("a"), $("b").count().as("cnt"));

// 打印
counts.execute().print();
~~~

下一个例子展示了一个更加复杂的 Table API 程序。这个程序也扫描 Orders 表。程序过滤了空值，使字符串类型的字段 a
标准化，并且每个小时进行一次计算并返回 a 的平均账单金额 b。

~~~
// 环境配置
// ...

// 指定表程序
Table orders = tEnv.from("Orders"); // schema (a, b, c, rowtime)

Table result = orders
        .filter(
            and(
                $("a").isNotNull(),
                $("b").isNotNull(),
                $("c").isNotNull()
            ))
        .select($("a").lowerCase().as("a"), $("b"), $("rowtime"))
        .window(Tumble.over(lit(1).hours()).on($("rowtime")).as("hourlyWindow"))
        .groupBy($("hourlyWindow"), $("a"))
        .select($("a"), $("hourlyWindow").end().as("hour"), $("b").avg().as("avgBillingAmount"));
~~~

因为 Table API 的批数据 API 和流数据 API
是统一的，所以这两个例子程序不需要修改代码就可以运行在流输入或批输入上。在这两种情况下，只要流任务没有数据延时，程序将会输出相同的结果（查看流概念获取详情)。

## Operations

Table API支持如下操作。请注意不是所有的操作都可以既支持流也支持批；这些操作都具有相应的标记。

### Scan, Projection, and Filter

#### From

`Batch` `Streaming`

和 SQL 查询的 FROM 子句类似。 执行一个注册过的表的扫描。

~~~
Table orders = tableEnv.from("Orders");
~~~

#### FromValues

`Batch` `Streaming`

和 SQL 查询中的 VALUES 子句类似。 基于提供的行生成一张内联表。

你可以使用 row(...) 表达式创建复合行：

~~~
Table table = tEnv.fromValues(
   row(1, "ABC"),
   row(2L, "ABCDE")
);
~~~

这将生成一张结构如下的表：

~~~
root
|-- f0: BIGINT NOT NULL     // original types INT and BIGINT are generalized to BIGINT
|-- f1: VARCHAR(5) NOT NULL // original types CHAR(3) and CHAR(5) are generalized
                            // to VARCHAR(5). VARCHAR is used instead of CHAR so that
                            // no padding is applied
~~~

这个方法会根据输入的表达式自动获取类型。如果在某一个特定位置的类型不一致，该方法会尝试寻找一个所有类型的公共超类型。如果公共超类型不存在，则会抛出异常。

你也可以明确指定所需的类型。指定如 DECIMAL 这样的一般类型或者给列命名可能是有帮助的。

~~~
Table table = tEnv.fromValues(
    DataTypes.ROW(
        DataTypes.FIELD("id", DataTypes.DECIMAL(10, 2)),
        DataTypes.FIELD("name", DataTypes.STRING())
    ),
    row(1, "ABC"),
    row(2L, "ABCDE")
);
~~~

这将生成一张结构如下的表：

~~~
root
|-- id: DECIMAL(10, 2)
|-- name: STRING
~~~

#### Select

`Batch` `Streaming`

和 SQL 的 SELECT 子句类似。 执行一个 select 操作。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.select($("a"), $("c").as("d"));
~~~

你可以选择星号（*）作为通配符，select 表中的所有列。

~~~
Table result = orders.select($("*"));
~~~

#### As

`Batch` `Streaming`

重命名字段。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.as("x, y, z, t");
~~~

#### Where / Filter

`Batch` `Streaming`

和 SQL 的 WHERE 子句类似。 过滤掉未验证通过过滤谓词的行。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.where($("b").isEqual("red"));
~~~

或者

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.filter($("b").isEqual("red"));
~~~

### 列操作

#### AddColumns

`Batch` `Streaming`

执行字段添加操作。 如果所添加的字段已经存在，将抛出异常。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.addColumns(concat($("c"), "sunny"));
~~~

#### AddOrReplaceColumns

`Batch` `Streaming`

执行字段添加操作。 如果添加的列名称和已存在的列名称相同，则已存在的字段将被替换。 此外，如果添加的字段里面有重复的字段名，则会使用最后一个字段。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.addOrReplaceColumns(concat($("c"), "sunny").as("desc"));
~~~

#### DropColumns

`Batch` `Streaming`

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.dropColumns($("b"), $("c"));
~~~

#### RenameColumns

`Batch` `Streaming`

执行字段重命名操作。 字段表达式应该是别名表达式，并且仅当字段已存在时才能被重命名。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.renameColumns($("b").as("b2"), $("c").as("c2"));
~~~

### Aggregations

#### GroupBy Aggregation

`Batch` `Streaming` `Result Updating`

和 SQL 的 GROUP BY 子句类似。 使用分组键对行进行分组，使用伴随的聚合算子来按照组进行聚合行。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.groupBy($("a")).select($("a"), $("b").sum().as("d"));
~~~

For streaming queries the required state to compute the query result might grow infinitely depending on the type of
aggregation and the number of distinct grouping keys. Please provide an idle state retention time to prevent excessive
state size. See [Idle State Retention Time]() for details.

#### GroupBy Window Aggregation

`Batch` `Streaming`

使用[分组窗口]()结合单个或者多个分组键对表进行分组和聚合。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders
    .window(Tumble.over(lit(5).minutes()).on($("rowtime")).as("w")) // 定义窗口
    .groupBy($("a"), $("w")) // 按窗口和键分组
    // 访问窗口属性并聚合
    .select(
        $("a"),
        $("w").start(),
        $("w").end(),
        $("w").rowtime(),
        $("b").sum().as("d")
    );
~~~

#### Over Window Aggregation

和 SQL 的 OVER 子句类似。 更多细节详见 [over windows section]()

~~~
Table orders = tableEnv.from("Orders");
Table result = orders
    // 定义窗口
    .window(
        Over
          .partitionBy($("a"))
          .orderBy($("rowtime"))
          .preceding(UNBOUNDED_RANGE)
          .following(CURRENT_RANGE)
          .as("w"))
    // 滑动聚合
    .select(
        $("a"),
        $("b").avg().over($("w")),
        $("b").max().over($("w")),
        $("b").min().over($("w"))
    );
~~~

所有的聚合必须定义在同一个窗口上，比如同一个分区、排序和范围内。目前只支持 PRECEDING 到当前行范围（无界或有界）的窗口。尚不支持
FOLLOWING 范围的窗口。ORDER BY 操作必须指定一个单一的[时间属性]()。

#### Distinct Aggregation

`Batch` `Streaming` `Result Updating`

和 SQL DISTINCT 聚合子句类似，例如 COUNT(DISTINCT a)。 Distinct 聚合声明的聚合函数（内置或用户定义的）仅应用于互不相同的输入值。
Distinct 可以应用于 **GroupBy Aggregation**、**GroupBy Window Aggregation** 和 **Over Window Aggregation**。

~~~
Table orders = tableEnv.from("Orders");
// 按属性分组后的的互异（互不相同、去重）聚合
Table groupByDistinctResult = orders
    .groupBy($("a"))
    .select($("a"), $("b").sum().distinct().as("d"));
// 按属性、时间窗口分组后的互异（互不相同、去重）聚合
Table groupByWindowDistinctResult = orders
    .window(Tumble
            .over(lit(5).minutes())
            .on($("rowtime"))
            .as("w")
    )
    .groupBy($("a"), $("w"))
    .select($("a"), $("b").sum().distinct().as("d"));
// over window 上的互异（互不相同、去重）聚合
Table result = orders
    .window(Over
        .partitionBy($("a"))
        .orderBy($("rowtime"))
        .preceding(UNBOUNDED_RANGE)
        .as("w"))
    .select(
        $("a"), $("b").avg().distinct().over($("w")),
        $("b").max().over($("w")),
        $("b").min().over($("w"))
    );
~~~

用户定义的聚合函数也可以与 DISTINCT 修饰符一起使用。如果计算不同（互异、去重的）值的聚合结果，则只需向聚合函数添加 distinct
修饰符即可。

~~~
Table orders = tEnv.from("Orders");

// 对 user-defined aggregate functions 使用互异（互不相同、去重）聚合
tEnv.registerFunction("myUdagg", new MyUdagg());
orders.groupBy("users")
    .select(
        $("users"),
        call("myUdagg", $("points")).distinct().as("myDistinctResult")
    );
~~~

For streaming queries the required state to compute the query result might grow infinitely depending on the type of
aggregation and the number of distinct grouping keys. Please provide an idle state retention time to prevent excessive
state size. See [Idle State Retention Time]() for details.

#### Distinct

`Batch` `Streaming` `Result Updating`

和 SQL 的 DISTINCT 子句类似。 返回具有不同组合值的记录。

~~~
Table orders = tableEnv.from("Orders");
Table result = orders.distinct();
~~~

For streaming queries the required state to compute the query result might grow infinitely depending on the type of
aggregation and the number of distinct grouping keys. Please provide an idle state retention time to prevent excessive
state size. See [Idle State Retention Time]() for details.

### Joins

#### Inner Join

`Batch` `Streaming`

和 SQL 的 JOIN 子句类似。关联两张表。两张表必须有不同的字段名，并且必须通过 join 算子或者使用 where 或 filter 算子定义至少一个
join 等式连接谓词。

~~~
Table left = tableEnv.from("MyTable").select($("a"), $("b"), $("c"));
Table right = tableEnv.from("MyTable").select($("d"), $("e"), $("f"));
Table result = left.join(right)
    .where($("a").isEqual($("d")))
    .select($("a"), $("b"), $("e"));
~~~

For streaming queries the required state to compute the query result might grow infinitely depending on the type of
aggregation and the number of distinct grouping keys. Please provide an idle state retention time to prevent excessive
state size. See [Idle State Retention Time]() for details.

#### Outer Join

`Batch` `Streaming` `Result Updating`

和 SQL LEFT/RIGHT/FULL OUTER JOIN 子句类似。 关联两张表。 两张表必须有不同的字段名，并且必须定义至少一个等式连接谓词。

~~~
Table left = tableEnv.from("MyTable").select($("a"), $("b"), $("c"));
Table right = tableEnv.from("MyTable").select($("d"), $("e"), $("f"));

Table leftOuterResult = left.leftOuterJoin(right, $("a").isEqual($("d")))
                            .select($("a"), $("b"), $("e"));
Table rightOuterResult = left.rightOuterJoin(right, $("a").isEqual($("d")))
                            .select($("a"), $("b"), $("e"));
Table fullOuterResult = left.fullOuterJoin(right, $("a").isEqual($("d")))
                            .select($("a"), $("b"), $("e"));
~~~

For streaming queries the required state to compute the query result might grow infinitely depending on the type of
aggregation and the number of distinct grouping keys. Please provide an idle state retention time to prevent excessive
state size. See [Idle State Retention Time]() for details.

#### Interval Join

`Batch` `Streaming`

Interval join 是可以通过流模式处理的常规 join 的子集。

Interval join 至少需要一个 equi-join 谓词和一个限制双方时间界限的 join 条件。这种条件可以由两个合适的范围谓词（<、<=、>=、>
）或一个比较两个输入表相同时间属性（即处理时间或事件时间）的等值谓词来定义。

~~~
Table left = tableEnv.from("MyTable").select($("a"), $("b"), $("c"), $("ltime"));
Table right = tableEnv.from("MyTable").select($("d"), $("e"), $("f"), $("rtime"));

Table result = left.join(right)
  .where(
    and(
        $("a").isEqual($("d")),
        $("ltime").isGreaterOrEqual($("rtime").minus(lit(5).minutes())),
        $("ltime").isLess($("rtime").plus(lit(10).minutes()))
    ))
  .select($("a"), $("b"), $("e"), $("ltime"));
~~~

#### Inner Join with Table Function (UDTF)

`Batch` `Streaming`

join 表和表函数的结果。左（外部）表的每一行都会 join 表函数相应调用产生的所有行。 如果表函数调用返回空结果，则删除左侧（外部）表的一行。

~~~
// 注册 User-Defined Table Function
TableFunction<Tuple3<String,String,String>> split = new MySplitUDTF();
tableEnv.registerFunction("split", split);

// join
Table orders = tableEnv.from("Orders");
Table result = orders
    .joinLateral(call("split", $("c")).as("s", "t", "v"))
    .select($("a"), $("b"), $("s"), $("t"), $("v"));
~~~

#### Left Outer Join with Table Function (UDTF)

`Batch` `Streaming`

join 表和表函数的结果。左（外部）表的每一行都会 join 表函数相应调用产生的所有行。如果表函数调用返回空结果，则保留相应的
outer（外部连接）行并用空值填充右侧结果。

目前，表函数左外连接的谓词只能为空或字面（常量）真。

~~~
// 注册 User-Defined Table Function
TableFunction<Tuple3<String,String,String>> split = new MySplitUDTF();
tableEnv.registerFunction("split", split);

// join
Table orders = tableEnv.from("Orders");
Table result = orders
    .leftOuterJoinLateral(call("split", $("c")).as("s", "t", "v"))
    .select($("a"), $("b"), $("s"), $("t"), $("v"));
~~~

#### Join with Temporal Table

Temporal table 是跟踪随时间变化的表。

Temporal table 函数提供对特定时间点 temporal table 状态的访问。表与 temporal table 函数进行 join 的语法和使用表函数进行
inner join 的语法相同。

目前仅支持与 temporal table 的 inner join。

~~~
Table ratesHistory = tableEnv.from("RatesHistory");

// 注册带有时间属性和主键的 temporal table function
TemporalTableFunction rates = ratesHistory.createTemporalTableFunction(
    "r_proctime",
    "r_currency");
tableEnv.registerFunction("rates", rates);

// 基于时间属性和键与“Orders”表关联
Table orders = tableEnv.from("Orders");
Table result = orders
    .joinLateral(call("rates", $("o_proctime")), $("o_currency").isEqual($("r_currency")));
~~~

### Set Operations

#### Union

`Batch`
和 SQL UNION 子句类似。Union 两张表会删除重复记录。两张表必须具有相同的字段类型。

~~~
Table left = tableEnv.from("orders1");
Table right = tableEnv.from("orders2");

left.union(right);
~~~

#### UnionAll

`Batch` `Streaming`

和 SQL UNION ALL 子句类似。Union 两张表。 两张表必须具有相同的字段类型。

~~~
Table left = tableEnv.from("orders1");
Table right = tableEnv.from("orders2");

left.unionAll(right);
~~~

#### Intersect

`Batch`
和 SQL INTERSECT 子句类似。Intersect 返回两个表中都存在的记录。如果一条记录在一张或两张表中存在多次，则只返回一条记录，也就是说，结果表中不存在重复的记录。两张表必须具有相同的字段类型。

~~~
Table left = tableEnv.from("orders1");
Table right = tableEnv.from("orders2");

left.intersect(right);
~~~

#### IntersectAll

`Batch`
和 SQL INTERSECT ALL 子句类似。IntersectAll
返回两个表中都存在的记录。如果一条记录在两张表中出现多次，那么该记录返回的次数同该记录在两个表中都出现的次数一致，也就是说，结果表可能存在重复记录。两张表必须具有相同的字段类型。

~~~
Table left = tableEnv.from("orders1");
Table right = tableEnv.from("orders2");

left.intersectAll(right);
~~~

#### Minus

`Batch`

和 SQL EXCEPT 子句类似。Minus 返回左表中存在且右表中不存在的记录。左表中的重复记录只返回一次，换句话说，结果表中没有重复记录。两张表必须具有相同的字段类型。

~~~
Table left = tableEnv.from("orders1");
Table right = tableEnv.from("orders2");

left.minus(right);
~~~

#### MinusAll

`Batch`

和 SQL EXCEPT ALL 子句类似。MinusAll 返回右表中不存在的记录。在左表中出现 n 次且在右表中出现 m 次的记录，在结果表中出现 (
n - m) 次，例如，也就是说结果中删掉了在右表中存在重复记录的条数的记录。两张表必须具有相同的字段类型。

~~~
Table left = tableEnv.from("orders1");
Table right = tableEnv.from("orders2");

left.minusAll(right);
~~~

#### In

`Batch` `Streaming`

和 SQL IN 子句类似。如果表达式的值存在于给定表的子查询中，那么 In 子句返回 true。子查询表必须由一列组成。这个列必须与表达式具有相同的数据类型。

~~~
Table left = tableEnv.from("Orders1")
Table right = tableEnv.from("Orders2");

Table result = left.select($("a"), $("b"), $("c")).where($("a").in(right));
~~~

For streaming queries the required state to compute the query result might grow infinitely depending on the type of
aggregation and the number of distinct grouping keys. Please provide an idle state retention time to prevent excessive
state size. See [Idle State Retention Time]() for details.
Back to top

### OrderBy, Offset & Fetch

#### Order By

`Batch` `Streaming`

和 SQL ORDER BY 子句类似。返回跨所有并行分区的全局有序记录。对于无界表，该操作需要对时间属性进行排序或进行后续的 fetch 操作。

~~~
Table result = tab.orderBy($("a").asc());
~~~

#### Offset & Fetch

`Batch` `Streaming`

和 SQL 的 OFFSET 和 FETCH 子句类似。Offset 操作根据偏移位置来限定（可能是已排序的）结果集。Fetch 操作将（可能已排序的）结果集限制为前
n 行。通常，这两个操作前面都有一个排序操作。对于无界表，offset 操作需要 fetch 操作。

~~~
// 从已排序的结果集中返回前5条记录
Table result1 = in.orderBy($("a").asc()).fetch(5);

// 从已排序的结果集中返回跳过3条记录之后的所有记录
Table result2 = in.orderBy($("a").asc()).offset(3);

// 从已排序的结果集中返回跳过10条记录之后的前5条记录
Table result3 = in.orderBy($("a").asc()).offset(10).fetch(5);
~~~

### Insert

`Batch` `Streaming`

和 SQL 查询中的 INSERT INTO 子句类似，该方法执行对已注册的输出表的插入操作。 insertInto() 方法会将 INSERT INTO 转换为一个
TablePipeline。 该数据流可以用 TablePipeline.explain() 来解释，用 TablePipeline.execute() 来执行。

输出表必须已注册在 TableEnvironment（详见表连接器）中。此外，已注册表的 schema 必须与查询中的 schema 相匹配。

~~~
Table orders = tableEnv.from("Orders");
orders.insertInto("OutOrders").execute();
~~~

### Group Windows

Group window 聚合根据时间或行计数间隔将行分为有限组，并为每个分组进行一次聚合函数计算。对于批处理表，窗口是按时间间隔对记录进行分组的便捷方式。

窗口是使用 window(GroupWindow w) 子句定义的，并且需要使用 as 子句来指定别名。为了按窗口对表进行分组，窗口别名的引用必须像常规分组属性一样在
groupBy(...) 子句中。 以下示例展示了如何在表上定义窗口聚合。

~~~
Table table = input
  .window([GroupWindow w].as("w"))  // 定义窗口并指定别名为 w
  .groupBy($("w"))  // 以窗口 w 对表进行分组
  .select($("b").sum());  // 聚合
~~~

在流环境中，如果窗口聚合除了窗口之外还根据一个或多个属性进行分组，则它们只能并行计算，例如，groupBy(...)
子句引用了一个窗口别名和至少一个附加属性。仅引用窗口别名（例如在上面的示例中）的 groupBy(...) 子句只能由单个非并行任务进行计算。
以下示例展示了如何定义有附加分组属性的窗口聚合。

~~~
Table table = input
  .window([GroupWindow w].as("w"))  // 定义窗口并指定别名为 w
  .groupBy($("w"), $("a"))  // 以属性 a 和窗口 w 对表进行分组
  .select($("a"), $("b").sum());  // 聚合
~~~

时间窗口的开始、结束或行时间戳等窗口属性可以作为窗口别名的属性添加到 select 子句中，如 w.start、w.end 和
w.rowtime。窗口开始和行时间戳是包含的上下窗口边界。相反，窗口结束时间戳是唯一的上窗口边界。例如，从下午 2 点开始的 30 分钟滚动窗口将
“14:00:00.000” 作为开始时间戳，“14:29:59.999” 作为行时间时间戳，“14:30:00.000” 作为结束时间戳。

~~~
Table table = input
  .window([GroupWindow w].as("w"))  // 定义窗口并指定别名为 w
  .groupBy($("w"), $("a"))  // 以属性 a 和窗口 w 对表进行分组
  .select($("a"), $("w").start(), $("w").end(), $("w").rowtime(), $("b").count()); // 聚合并添加窗口开始、结束和 rowtime 时间戳
~~~

Window 参数定义了如何将行映射到窗口。 Window 不是用户可以实现的接口。相反，Table API 提供了一组具有特定语义的预定义 Window
类。下面列出了支持的窗口定义。

#### Tumble (Tumbling Windows)

滚动窗口将行分配给固定长度的非重叠连续窗口。例如，一个 5 分钟的滚动窗口以 5 分钟的间隔对行进行分组。滚动窗口可以定义在事件时间、处理时间或行数上。

滚动窗口是通过 Tumble 类定义的，具体如下：

| Method | Description                                                                          |
|--------|--------------------------------------------------------------------------------------|
| over   | 将窗口的长度定义为时间或行计数间隔。                                                                   |
| on     | 要对数据进行分组（时间间隔）或排序（行计数）的时间属性。批处理查询支持任意 Long 或 Timestamp 类型的属性。流处理查询仅支持声明的事件时间或处理时间属性。 |
| as     | 指定窗口的别名。别名用于在 groupBy() 子句中引用窗口，并可以在 select() 子句中选择如窗口开始、结束或行时间戳的窗口属性。               |

~~~
// Tumbling Event-time Window
.window(Tumble.over(lit(10).minutes()).on($("rowtime")).as("w"));

// Tumbling Processing-time Window (assuming a processing-time attribute "proctime")
.window(Tumble.over(lit(10).minutes()).on($("proctime")).as("w"));

// Tumbling Row-count Window (assuming a processing-time attribute "proctime")
.window(Tumble.over(rowInterval(10)).on($("proctime")).as("w"));
~~~

#### Slide (Sliding Windows)

滑动窗口具有固定大小并按指定的滑动间隔滑动。如果滑动间隔小于窗口大小，则滑动窗口重叠。因此，行可能分配给多个窗口。例如，15
分钟大小和 5 分钟滑动间隔的滑动窗口将每一行分配给 3 个不同的 15 分钟大小的窗口，以 5 分钟的间隔进行一次计算。滑动窗口可以定义在事件时间、处理时间或行数上。

Java
滑动窗口是通过 Slide 类定义的，具体如下：

| Method | Description                                                                          |
|--------|--------------------------------------------------------------------------------------|
| over   | 将窗口的长度定义为时间或行计数间隔。                                                                   |
| every  | 将窗口的长度定义为时间或行计数间隔。滑动间隔的类型必须与窗口长度的类型相同。                                               |
| on     | 要对数据进行分组（时间间隔）或排序（行计数）的时间属性。批处理查询支持任意 Long 或 Timestamp 类型的属性。流处理查询仅支持声明的事件时间或处理时间属性。 |
| as     | 指定窗口的别名。别名用于在 groupBy() 子句中引用窗口，并可以在 select() 子句中选择如窗口开始、结束或行时间戳的窗口属性。               |

~~~
// Sliding Event-time Window
.window(Slide.over(lit(10).minutes())
            .every(lit(5).minutes())
            .on($("rowtime"))
            .as("w"));

// Sliding Processing-time window (assuming a processing-time attribute "proctime")
.window(Slide.over(lit(10).minutes())
            .every(lit(5).minutes())
            .on($("proctime"))
            .as("w"));

// Sliding Row-count window (assuming a processing-time attribute "proctime")
.window(Slide.over(rowInterval(10)).every(rowInterval(5)).on($("proctime")).as("w"));
~~~

#### Session (Session Windows)

会话窗口没有固定的大小，其边界是由不活动的间隔定义的，例如，如果在定义的间隔期内没有事件出现，则会话窗口将关闭。例如，定义30
分钟间隔的会话窗口，当观察到一行在 30 分钟内不活动（否则该行将被添加到现有窗口中）且30 分钟内没有添加新行，窗口会关闭。会话窗口支持事件时间和处理时间。

| Method  | Description                                                                          |
|---------|--------------------------------------------------------------------------------------|
| withGap | 将两个窗口之间的间隙定义为时间间隔。                                                                   |
| on      | 要对数据进行分组（时间间隔）或排序（行计数）的时间属性。批处理查询支持任意 Long 或 Timestamp 类型的属性。流处理查询仅支持声明的事件时间或处理时间属性。 |
| as      | 指定窗口的别名。别名用于在 groupBy() 子句中引用窗口，并可以在 select() 子句中选择如窗口开始、结束或行时间戳的窗口属性。               |

~~~
// Session Event-time Window
.window(Session.withGap(lit(10).minutes()).on($("rowtime")).as("w"));

// Session Processing-time Window (assuming a processing-time attribute "proctime")
.window(Session.withGap(lit(10).minutes()).on($("proctime")).as("w"));
~~~

#### Over Windows

Over window 聚合聚合来自在标准的 SQL（OVER 子句），可以在 SELECT 查询子句中定义。与在“GROUP BY”子句中指定的 group window 不同，
over window 不会折叠行。相反，over window 聚合为每个输入行在其相邻行的范围内计算聚合。

Over windows 使用 window(w: OverWindow*) 子句（在 Python API 中使用 over_window(*OverWindow)）定义，并通过 select()
方法中的别名引用。以下示例显示如何在表上定义 over window 聚合。

~~~
Table table = input
  .window([OverWindow w].as("w"))           // define over window with alias w
  .select($("a"), $("b").sum().over($("w")), $("c").min().over($("w"))); // aggregate over the over window w
~~~

OverWindow 定义了计算聚合的行范围。OverWindow 不是用户可以实现的接口。相反，Table API 提供了Over 类来配置 over window
的属性。可以在事件时间或处理时间以及指定为时间间隔或行计数的范围内定义 over window 。可以通过 Over 类（和其他类）上的方法来定义
over window，具体如下：

#### Partition By

`可选的`

在一个或多个属性上定义输入的分区。每个分区单独排序，聚合函数分别应用于每个分区。

注意：在流环境中，如果窗口包含 partition by 子句，则只能并行计算 over window 聚合。如果没有 partitionBy(…)，数据流将由单个非并行任务处理。

#### Order By

`必须的`

定义每个分区内行的顺序，从而定义聚合函数应用于行的顺序。

注意：对于流处理查询，必须声明事件时间或处理时间属性。目前，仅支持单个排序属性。

#### Preceding

`可选的`

定义了包含在窗口中并位于当前行之前的行的间隔。间隔可以是时间或行计数间隔。

有界 over window 用间隔的大小指定，例如，时间间隔为10分钟或行计数间隔为10行。

无界 over window 通过常量来指定，例如，用UNBOUNDED_RANGE指定时间间隔或用 UNBOUNDED_ROW 指定行计数间隔。无界 over windows
从分区的第一行开始。

如果省略前面的子句，则使用 UNBOUNDED_RANGE 和 CURRENT_RANGE 作为窗口前后的默认值。

#### Following

`可选的`

定义包含在窗口中并在当前行之后的行的窗口间隔。间隔必须以与前一个间隔（时间或行计数）相同的单位指定。

目前，不支持在当前行之后有行的 over window。相反，你可以指定两个常量之一：

CURRENT_ROW 将窗口的上限设置为当前行。
CURRENT_RANGE 将窗口的上限设置为当前行的排序键，例如，与当前行具有相同排序键的所有行都包含在窗口中。
如果省略后面的子句，则时间间隔窗口的上限定义为 CURRENT_RANGE，行计数间隔窗口的上限定义为CURRENT_ROW。

#### As

`必须的`

为 over window 指定别名。别名用于在之后的 select() 子句中引用该 over window。

注意：目前，同一个 select() 调用中的所有聚合函数必须在同一个 over window 上计算。

##### Unbounded Over Windows

~~~
// 无界的事件时间 over window（假定有一个叫“rowtime”的事件时间属性）
.window(Over.partitionBy($("a")).orderBy($("rowtime")).preceding(UNBOUNDED_RANGE).as("w"));

// 无界的处理时间 over window（假定有一个叫“proctime”的处理时间属性）
.window(Over.partitionBy($("a")).orderBy("proctime").preceding(UNBOUNDED_RANGE).as("w"));

// 无界的事件时间行数 over window（假定有一个叫“rowtime”的事件时间属性）
.window(Over.partitionBy($("a")).orderBy($("rowtime")).preceding(UNBOUNDED_ROW).as("w"));
 
// 无界的处理时间行数 over window（假定有一个叫“proctime”的处理时间属性）
.window(Over.partitionBy($("a")).orderBy($("proctime")).preceding(UNBOUNDED_ROW).as("w"));
~~~

##### Bounded Over Windows

~~~
// 有界的事件时间 over window（假定有一个叫“rowtime”的事件时间属性）
.window(Over.partitionBy($("a")).orderBy($("rowtime")).preceding(lit(1).minutes()).as("w"));

// 有界的处理时间 over window（假定有一个叫“proctime”的处理时间属性）
.window(Over.partitionBy($("a")).orderBy($("proctime")).preceding(lit(1).minutes()).as("w"));

// 有界的事件时间行数 over window（假定有一个叫“rowtime”的事件时间属性）
.window(Over.partitionBy($("a")).orderBy($("rowtime")).preceding(rowInterval(10)).as("w"));
 
// 有界的处理时间行数 over window（假定有一个叫“proctime”的处理时间属性）
.window(Over.partitionBy($("a")).orderBy($("proctime")).preceding(rowInterval(10)).as("w"));
~~~

### Row-based Operations

基于行生成多列输出的操作。

#### Map

`Batch` `Streaming`

使用用户定义的标量函数或内置标量函数执行 map 操作。如果输出类型是复合类型，则输出将被展平。

~~~
public class MyMapFunction extends ScalarFunction {
    public Row eval(String a) {
        return Row.of(a, "pre-" + a);
    }

    @Override
    public TypeInformation<?> getResultType(Class<?>[] signature) {
        return Types.ROW(Types.STRING(), Types.STRING());
    }
}

ScalarFunction func = new MyMapFunction();
tableEnv.registerFunction("func", func);

Table table = input
  .map(call("func", $("c")).as("a", "b"));
~~~

#### FlatMap

`Batch` `Streaming`

使用表函数执行 flatMap 操作。

~~~
public class MyFlatMapFunction extends TableFunction<Row> {

    public void eval(String str) {
        if (str.contains("#")) {
            String[] array = str.split("#");
            for (int i = 0; i < array.length; ++i) {
                collect(Row.of(array[i], array[i].length()));
            }
        }
    }

    @Override
    public TypeInformation<Row> getResultType() {
        return Types.ROW(Types.STRING(), Types.INT());
    }
}

TableFunction func = new MyFlatMapFunction();
tableEnv.registerFunction("func", func);

Table table = input
  .flatMap(call("func", $("c")).as("a", "b"));
~~~

#### Aggregate

`Batch` `Streaming` `Result`

使用聚合函数来执行聚合操作。你必须使用 select 子句关闭 aggregate，并且 select 子句不支持聚合函数。如果输出类型是复合类型，则聚合的输出将被展平。

~~~
public class MyMinMaxAcc {
    public int min = 0;
    public int max = 0;
}

public class MyMinMax extends AggregateFunction<Row, MyMinMaxAcc> {

    public void accumulate(MyMinMaxAcc acc, int value) {
        if (value < acc.min) {
            acc.min = value;
        }
        if (value > acc.max) {
            acc.max = value;
        }
    }

    @Override
    public MyMinMaxAcc createAccumulator() {
        return new MyMinMaxAcc();
    }

    public void resetAccumulator(MyMinMaxAcc acc) {
        acc.min = 0;
        acc.max = 0;
    }

    @Override
    public Row getValue(MyMinMaxAcc acc) {
        return Row.of(acc.min, acc.max);
    }

    @Override
    public TypeInformation<Row> getResultType() {
        return new RowTypeInfo(Types.INT, Types.INT);
    }
}

AggregateFunction myAggFunc = new MyMinMax();
tableEnv.registerFunction("myAggFunc", myAggFunc);
Table table = input
  .groupBy($("key"))
  .aggregate(call("myAggFunc", $("a")).as("x", "y"))
  .select($("key"), $("x"), $("y"));
~~~

#### Group Window Aggregate

`Batch` `Streaming`

在 [group window]() 和可能的一个或多个分组键上对表进行分组和聚合。你必须使用 select 子句关闭 aggregate。并且 select
子句不支持“*“或聚合函数。

~~~
AggregateFunction myAggFunc = new MyMinMax();
tableEnv.registerFunction("myAggFunc", myAggFunc);

Table table = input
    .window(Tumble.over(lit(5).minutes())
                  .on($("rowtime"))
                  .as("w")) // 定义窗口
    .groupBy($("key"), $("w")) // 以键和窗口分组
    .aggregate(call("myAggFunc", $("a")).as("x", "y"))
    .select($("key"), $("x"), $("y"), $("w").start(), $("w").end()); // 访问窗口属性与聚合结果
~~~

#### FlatAggregate

和 **GroupBy Aggregation** 类似。使用运行中的表之后的聚合算子对分组键上的行进行分组，以按组聚合行。和 AggregateFunction
的不同之处在于，TableAggregateFunction 的每个分组可能返回0或多条记录。你必须使用 select 子句关闭 flatAggregate。并且 select
子句不支持聚合函数。

除了使用 emitValue 输出结果，你还可以使用 emitUpdateWithRetract 方法。和 emitValue 不同的是，emitUpdateWithRetract
用于下发已更新的值。此方法在retract 模式下增量输出数据，例如，一旦有更新，我们必须在发送新的更新记录之前收回旧记录。如果在表聚合函数中定义了这两个方法，则将优先使用
emitUpdateWithRetract 方法而不是 emitValue 方法，这是因为该方法可以增量输出值，因此被视为比 emitValue 方法更有效。

~~~
/**
 * Top2 Accumulator。
 */
public class Top2Accum {
    public Integer first;
    public Integer second;
}

/**
 * 用户定义的聚合函数 top2。
 */
public class Top2 extends TableAggregateFunction<Tuple2<Integer, Integer>, Top2Accum> {

    @Override
    public Top2Accum createAccumulator() {
        Top2Accum acc = new Top2Accum();
        acc.first = Integer.MIN_VALUE;
        acc.second = Integer.MIN_VALUE;
        return acc;
    }


    public void accumulate(Top2Accum acc, Integer v) {
        if (v > acc.first) {
            acc.second = acc.first;
            acc.first = v;
        } else if (v > acc.second) {
            acc.second = v;
        }
    }

    public void merge(Top2Accum acc, java.lang.Iterable<Top2Accum> iterable) {
        for (Top2Accum otherAcc : iterable) {
            accumulate(acc, otherAcc.first);
            accumulate(acc, otherAcc.second);
        }
    }

    public void emitValue(Top2Accum acc, Collector<Tuple2<Integer, Integer>> out) {
        // 下发 value 与 rank
        if (acc.first != Integer.MIN_VALUE) {
            out.collect(Tuple2.of(acc.first, 1));
        }
        if (acc.second != Integer.MIN_VALUE) {
            out.collect(Tuple2.of(acc.second, 2));
        }
    }
}

tEnv.registerFunction("top2", new Top2());
Table orders = tableEnv.from("Orders");
Table result = orders
    .groupBy($("key"))
    .flatAggregate(call("top2", $("a")).as("v", "rank"))
    .select($("key"), $("v"), $("rank");
~~~

For streaming queries the required state to compute the query result might grow infinitely depending on the type of
aggregation and the number of distinct grouping keys. Please provide an idle state retention time to prevent excessive
state size. See [Idle State Retention Time]() for details.

## 数据类型

请查看[数据类型]()的专门页面。

行中的字段可以是一般类型和(嵌套)复合类型(比如 POJO、元组、行、 Scala 案例类)。

任意嵌套的复合类型的字段都可以通过[值访问函数]()来访问。

[用户自定义函数]()可以将泛型当作黑匣子一样传输和处理。

