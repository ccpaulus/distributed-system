# SELECT 与 WHERE 子句

`Batch` `Streaming`

SELECT 语句的常见语法格式如下所示：

~~~
SELECT select_list FROM table_expression [ WHERE boolean_expression ]
~~~

这里的 table_expression 可以是任意的数据源。它可以是一张已经存在的表、视图或者 VALUES 子句，也可以是多个现有表的关联结果、或一个子查询。这里我们假设
Orders 表在 Catalog 中处于可用状态，那么下面的语句会从 Orders 表中读出所有的行。

~~~
SELECT * FROM Orders
~~~

在 select_list 处的 * 表示查询操作将会解析所有列。但是，我们不鼓励在生产中使用 *，因为它会使查询操作在应对 Catalog
变化的时候鲁棒性降低。相反，可以在 select_list 处指定可用列的子集，或者使用声明的列进行计算。例如，假设 Orders 表中有名为
order_id、price 和 tax 的列，那么你可以编写如下查询：

~~~
SELECT order_id, price + tax FROM Orders
~~~

查询操作还可以在 VALUES 子句中使用内联数据。每一个元组对应一行，另外可以通过设置别名来为每一列指定名称。

~~~
SELECT order_id, price FROM (VALUES (1, 2.0), (2, 3.1))  AS t (order_id, price)
~~~

可以根据 WHERE 子句对行数据进行过滤。

~~~
SELECT price + tax FROM Orders WHERE id = 10
~~~

此外，在任意一行的列上你可以调用内置函数和用户自定义标量函数（user-defined scalar functions）。当然，在使用前用户自定义函数（
user-defined functions）必须已经注册到 Catalog 中。

~~~
SELECT PRETTY_PRINT(order_id) FROM Orders
~~~

