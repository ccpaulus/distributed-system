# Data Pipelines & ETL

Apache Flink的一个非常常见的用例是实现`ETL(extract, transform, load)`管道，从一个或多个`sources`获得数据，进行一些`转换`
或`丰富`操作，然后将结果存储在某个地方。在本节中，我们将了解如何使用Flink的`DataStream API`来实现这类应用程序。

请注意，Flink的`Table and SQL APIs`非常适合许多ETL用例。但是，无论您最终是否直接使用`DataStream API`
，对本文介绍的基础知识有扎实的理解都是有价值的。

## Stateless Transformations

### map()

在第一个练习中，您过滤了出租车乘坐事件流。在相同的代码库中，有一个`GeoUtils`
类，它提供了一个静态方法`GeoUtils.mapToGridCell(float lon, float lat)`将位置(经度，纬度)
映射到一个网格单元，该网格单元指的是大约100 × 100米大小的区域。

现在，让我们通过向每个事件添加startCell和endCell字段来丰富我们的出租车乘车对象流。
您可以创建一个扩展TaxiRide的EnrichedRide对象，并添加这些字段：

~~~
public static class EnrichedRide extends TaxiRide {
    public int startCell;
    public int endCell;

    public EnrichedRide() {}

    public EnrichedRide(TaxiRide ride) {
        this.rideId = ride.rideId;
        this.isStart = ride.isStart;
        ...
        this.startCell = GeoUtils.mapToGridCell(ride.startLon, ride.startLat);
        this.endCell = GeoUtils.mapToGridCell(ride.endLon, ride.endLat);
    }

    public String toString() {
        return super.toString() + "," +
            Integer.toString(this.startCell) + "," +
            Integer.toString(this.endCell);
    }
}
~~~

然后，您可以创建一个转换流的应用程序

~~~
DataStream<TaxiRide> rides = env.addSource(new TaxiRideSource(...));

DataStream<EnrichedRide> enrichedNYCRides = rides
    .filter(new RideCleansingSolution.NYCFilter())
    .map(new Enrichment());

enrichedNYCRides.print();
~~~

使用此MapFunction：

~~~
public static class Enrichment implements MapFunction<TaxiRide, EnrichedRide> {

    @Override
    public EnrichedRide map(TaxiRide taxiRide) throws Exception {
        return new EnrichedRide(taxiRide);
    }
}
~~~

### flatmap()

`MapFunction`仅适用于执行一对一的转换：对于每个传入的流元素，map()将发出一个转换后的元素。除此以外，您可能需要使用flatmap()

~~~
DataStream<TaxiRide> rides = env.addSource(new TaxiRideSource(...));

DataStream<EnrichedRide> enrichedNYCRides = rides
    .flatMap(new NYCEnrichment());

enrichedNYCRides.print();
~~~

与`FlatMapFunction`一起：

~~~
public static class NYCEnrichment implements FlatMapFunction<TaxiRide, EnrichedRide> {

    @Override
    public void flatMap(TaxiRide taxiRide, Collector<EnrichedRide> out) throws Exception {
        FilterFunction<TaxiRide> valid = new RideCleansing.NYCFilter();
        if (valid.filter(taxiRide)) {
            out.collect(new EnrichedRide(taxiRide));
        }
    }
}
~~~

有了这个接口中提供的Collector, `flatmap()`方法可以发出`任意多的流元素`，包括`一个都不发出`。

## Keyed Streams

### keyBy()

能够围绕流的一个属性划分流通常是非常有用的，这样具有相同属性值的所有事件就可以分组在一起。例如，假设您想要查找从每个网格单元开始的最长出租车行程。
从SQL查询的角度来看，这意味着使用`startCell`进行某种`GROUP BY`，而在Flink中，这是使用`keyBy(KeySelector)`完成的。

~~~
rides
    .flatMap(new NYCEnrichment())
    .keyBy(enrichedRide -> enrichedRide.startCell);
~~~

每个`keyBy`都会引起网络`shuffle`，从而重新划分流。一般来说，这是相当昂贵的，因为它涉及到`网络通信`以及`序列化`和`反序列化`。

![](images/data-pipelines&etl/keyBy.png)

### Keys are computed

`KeySelectors`并不局限于从事件中提取`key`。相反，它们可以以想要的任何方式计算键，只要结果键是确定性的，并且具有`hashCode()`
和`equals()`的有效实现。
这个限制排除了`生成随机数`或`返回数组或枚举`的`KeySelectors`，但是可以使用`Tuples`或`POJOs`来拥有复合键，只要它们的元素遵循相同的规则。

`keys`必须以`确定的方式`生成，因为它们在需要时都会重新计算，而不是附加到流记录上。

例如，与其创建一个新的带有`startCell`字段的`EnrichedRide`类，然后把`startCell`作为键

~~~
keyBy(enrichedRide -> enrichedRide.startCell);
~~~

相反，可以这样做：

~~~
keyBy(ride -> GeoUtils.mapToGridCell(ride.startLon, ride.startLat));
~~~

### Aggregations on Keyed Streams

这段代码创建了一个新的元组流，其中包含每个乘车结束事件的`startCell`和`持续时间(单位为分钟)`

~~~
import org.joda.time.Interval;

DataStream<Tuple2<Integer, Minutes>> minutesByStartCell = enrichedNYCRides
    .flatMap(new FlatMapFunction<EnrichedRide, Tuple2<Integer, Minutes>>() {

        @Override
        public void flatMap(EnrichedRide ride,
                            Collector<Tuple2<Integer, Minutes>> out) throws Exception {
            if (!ride.isStart) {
                Interval rideInterval = new Interval(ride.startTime, ride.endTime);
                Minutes duration = rideInterval.toDuration().toStandardMinutes();
                out.collect(new Tuple2<>(ride.startCell, duration));
            }
        }
    });
~~~

现在可以生成一个流，其中只包含每个`startCell`所见过的最长的骑行(到该点)。

要用作键的字段有多种表示方式。前面看到了一个带有`EnrichedRide POJO`的示例，其中要用作键的字段是用其名称指定的。
这种情况涉及到`Tuple2`对象，并且使用元组内的索引(从0开始)来指定键。

~~~
minutesByStartCell
  .keyBy(value -> value.f0) // .keyBy(value -> value.startCell)
  .maxBy(1) // duration
  .print();
~~~

现在，每次持续时间达到新的最大值时，输出流都包含每个键的一条记录，如单元格50797所示

~~~
...
4> (64549,5M)
4> (46298,18M)
1> (51549,14M)
1> (53043,13M)
1> (56031,22M)
1> (50797,6M)
...
1> (50797,8M)
...
1> (50797,11M)
...
1> (50797,12M)
~~~

### (Implicit) State

这是本训练中涉及有状态流的第一个示例。虽然`state`是透明地处理的，但Flink必须跟踪每个不同`key`的最长持续时间。

无论何时在应用程序中涉及到`state`，您都应该考虑状态可能变得有多大。只要`key`空间是无界的，那么Flink需要的状态量也是无界的。

在处理流时，通常考虑`有限窗口上的聚合`比考虑整个流更有意义。

### reduce() and other aggregators

上面使用的`maxBy()`只是Flink的`KeyedStreams`上可用的许多聚合函数的一个例子。还有一个更通用的`reduce()`
函数，可以使用它来实现自定义聚合。

## Stateful Transformations

### Why is Flink Involved in Managing State?

您的应用程序当然能够在不让Flink参与管理`state`的情况下使用`state`，但Flink为其管理的`state`提供了一些引人注目的特性

* local：Flink的`state`保存在处理它的机器的本地，并且可以以内存速度访问
* durable：Flink的`state`是容错的，即定时自动`checkpoint`，故障时自动恢复
* vertically scalable：Flink的`state`可以保存在通过添加更多本地磁盘来扩展的`嵌入式RocksDB实例`中
* horizontally scalable：随着集群的增长和缩小，Flink的`state`会重新分布
* queryable：可以通过`Queryable state API`从外部查询Flink的`state`

在本节中，您将学习如何使用Flink管理`keyed state`的API。

### Rich Functions

至此，您已经看到了Flink的几个`function`接口，包括`FilterFunction`、`MapFunction`和`FlatMapFunction`。这些都是单一抽象方法模式的例子。

对于这些接口中的每一个，Flink还提供了一个所谓的`rich`变体，例如`RichFlatMapFunction`，它有一些额外的方法，包括：

* open(Configuration c)
* close()
* getRuntimeContext()

`open()`在`operator`初始化期间被调用一次。例如，这是加载一些`静态数据`或`打开到外部服务的连接`的机会。

`getRuntimeContext()`可以访问一整套可能有趣的东西的，但最值得注意的是如何创建和访问Flink管理的`state `。

### An Example with Keyed State

在这个示例中，假设有一个想要删除重复的事件流，这样就只保留每个键的第一个事件。
下面是一个应用程序，它使用了一个名为`Deduplicator`的`RichFlatMapFunction`

~~~
private static class Event {
    public final String key;
    public final long timestamp;
    ...
}

public static void main(String[] args) throws Exception {
    StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
  
    env.addSource(new EventSource())
        .keyBy(e -> e.key)
        .flatMap(new Deduplicator())
        .print();
  
    env.execute();
}
~~~

为了实现这一点，`Deduplicator`需要以某种方式记住每个key是否已经存在一个事件。它将使用Flink的`keyed state`接口来实现。

当像这样使用一个`keyed stream`时，Flink将为每一个`managed state`项（item）维护一个`key/value`存储。

Flink支持几种不同类型的`keyed state`，本例使用最简单的一种，即`ValueState`。这意味着对于每个key，Flink将存储一个对象(
在本例中是一个Boolean对象)。

`Deduplicator`类有两个方法:`open()`和`flatMap()`。open方法通过定义`ValueStateDescriptor<Boolean>`来建立`managed state`
的使用。
构造函数的参数为这个`keyed state("keyHasBeenSeen")`项指定一个名称，并提供可用于序列化这些对象的信息(
在本例中为`Types.BOOLEAN`)。

~~~
public static class Deduplicator extends RichFlatMapFunction<Event, Event> {
    ValueState<Boolean> keyHasBeenSeen;

    @Override
    public void open(Configuration conf) {
        ValueStateDescriptor<Boolean> desc = new ValueStateDescriptor<>("keyHasBeenSeen", Types.BOOLEAN);
        keyHasBeenSeen = getRuntimeContext().getState(desc);
    }

    @Override
    public void flatMap(Event event, Collector<Event> out) throws Exception {
        if (keyHasBeenSeen.value() == null) {
            out.collect(event);
            keyHasBeenSeen.update(true);
        }
    }
}
~~~

当`flatMap`方法调用`keyHasBeenSeen.value()`时，Flink的运行时在上下文中查找这段`state`的值以查找key，只有当它为`null`
时，它才会继续并将事件收集到输出中。在本例中，它还将`keyHasBeenSeen`更新为`true`。
