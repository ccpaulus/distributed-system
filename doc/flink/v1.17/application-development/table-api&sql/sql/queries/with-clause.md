# WITH 子句

`Batch` `Streaming`

WITH 子句提供了一种用于更大查询而编写辅助语句的方法。这些编写的语句通常被称为公用表表达式，表达式可以理解为仅针对某个查询而存在的临时视图。

WITH 子句的语法

~~~
WITH <with_item_definition> [ , ... ]
SELECT ... FROM ...;

<with_item_defintion>:
    with_item_name (column_name[, ...n]) AS ( <select_query> )
~~~

下面的示例中定义了一个公用表表达式 orders_with_total ，并在一个 GROUP BY 查询中使用它。

~~~
WITH orders_with_total AS (
    SELECT order_id, price + tax AS total
    FROM Orders
)
SELECT order_id, SUM(total)
FROM orders_with_total
GROUP BY order_id;
~~~

