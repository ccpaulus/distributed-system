# SELECT DISTINCT

`Batch` `Streaming`

如果使用”SELECT DISTINCT“查询,所有的复制行都会从结果集(每个分组只会保留一行)中被删除.

~~~
SELECT DISTINCT id FROM Orders
~~~

对于流式查询,
计算查询结果所需要的状态可能会源源不断地增长,而状态大小又依赖不同行的数量.此时,可以通过配置文件为状态设置合适的存活时间(
TTL),以防止过大的状态可能对查询结果的正确性的影响.具体配置可参考:查询相关的配置.

