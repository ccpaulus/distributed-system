# Streaming Analytics

## Event Time and Watermarks

### Introduction

Flink明确支持三种不同的时间概念：

* `event time`：由产生(或存储)该事件的设备所记录的事件发生的时间
* `ingestion time`：Flink在摄取事件时记录的时间戳
* `processing time`：管道中特定`operator`处理事件的时间

对于可重复的结果，例如，当计算股票在某一天交易的第一个小时内达到的最高价格时，您应该使用`event time`。这样，结果将不依赖于何时执行计算。
这种实时应用程序有时使用`processing time`执行，但是结果是由在该小时内碰巧处理的事件决定的，而不是由当时发生的事件决定的。
基于`processing time`的计算分析导致不一致，并且使重新分析历史数据或测试新实现变得困难。

### Working with Event Time

如果你想使用`event time`，你还需要提供一个时间戳提取器和`Watermark`生成器，Flink将使用它们来跟踪`event time`的进展。
这将在下面的`Working with Watermarks`一节中讨论，但首先我们应该解释什么是`Watermarks`。

### Watermarks

让我们通过一个简单的例子来说明为什么需要`Watermarks`，以及它们是如何工作的。

在这个示例中，您有一个带有时间戳的事件流，它们到达的顺序有些混乱，如下所示。显示的数字是时间戳，表示这些事件实际发生的时间。
第一个到达的事件发生在时间4，然后是在时间2之前发生的事件，依此类推

~~~
··· 23 19 22 24 21 14 17 13 12 15 9 11 7 2 4 →
~~~

现在假设您正在尝试创建一个流排序器。这意味着一个应用程序在流到达时处理每个事件，并发出一个包含相同事件的新流，但按其时间戳排序。

一些观察结果：

* (1)流排序器看到的第一个元素是`4`，但你不能立即释放它作为排序流的第一个元素。它可能不是按顺序到达的，而更早的事件可能还没有到达。
  实际上，您将受益于对这条流的未来有一些神一般的了解，您可以看到流排序器应该至少等到`2`到达后才产生任何结果。
  <br/>_**Some buffering, and some delay, is necessary.**_
* (2)如果你错误地处理此事，你可能会永远等下去。首先，排序器看到`时间4`的事件，然后是`时间2`的事件。
  时间戳小于`2`的事件是否会到达？也许会，也许不会。你可以永远等下去，永远看不到`1`。
  <br/>**_Eventually you have to be courageous and emit the 2 as the start of the sorted stream._**
* (3)那么，您需要的是某种策略，该策略定义对于任何给定的带有时间戳的事件，何时停止等待`较早事件的到来`。
  <br/>_**This is precisely what watermarks do — they define when to stop waiting for earlier events.**_
  <br/>Flink中的事件时间处理依赖于在流中插入特殊时间戳元素(称为`watermarks`)的`watermark生成器`。
  `时间t的watermark`是一个断言，即流(可能)在时间t中已经完备。
  <br/>这个流排序器何时应该`停止等待`，并推出`2`来启动排序流？当时间戳为`2`或更大的`watermarks`到达时。
* (4)你可以想象不同的策略来决定如何生成`watermarks`。
  <br/>每个事件在一定延迟之后到达，这些延迟各不相同，因此有些事件比其他事件延迟得更久。一种简单的方法是假设这些延迟受到某个最大延迟的限制。
  Flink将这种策略称为`bounded-out-of-orderness watermarking`。很容易想象更复杂的`watermarking`方法，但对于大多数应用来说，固定延迟就足够了。

### Latency vs. Completeness

考虑`watermarks`的另一种方式是，它们为流式应用程序的开发人员提供了在`延迟`和`完整性`之间的权衡。
这与批处理不同，在批处理中，人们可以在产生任何结果之前拥有完整的输入知识，而在流处理中，您最终必须`停止等待`
以查看更多的输入，并产生某种结果。

您可以使用`较短的有界延迟`积极地配置您的`watermarking`，从而承担在对输入的了解相当不完整的情况下生成结果的风险，例如，可能会快速生成错误的结果。
或者您可以等待`更长的时间`，并利用对输入流的更完整的了解来产生结果。

还可以实现快速产生初始结果的混合解决方案，然后在处理额外(后期)数据时对这些结果进行更新。对于某些应用程序来说，这是一种很好的方法。

### Lateness

延迟是相对于`watermarks`定义的。`watermarks(t)`断言流在到达`时间t`时是完整的；任何`时间戳 ≤ t`的事件都是延迟的。

### Working with Watermarks

为了执行基于事件时间的事件处理，Flink需要知道与每个事件相关的时间，并且它还需要流包含`watermarks`。

在实践练习中使用的Taxi数据源会为您处理这些细节。但是在您自己的应用程序中，您必须自己处理这个问题，
这通常是通过实现一个类来完成的，这个类从事件中提取时间戳，并根据需要生成`watermarks`。
最简单的方法就是使用`WatermarkStrategy`：

~~~
DataStream<Event> stream = ...;

WatermarkStrategy<Event> strategy = WatermarkStrategy
        .<Event>forBoundedOutOfOrderness(Duration.ofSeconds(20))
        .withTimestampAssigner((event, timestamp) -> event.timestamp);

DataStream<Event> withTimestampsAndWatermarks =
    stream.assignTimestampsAndWatermarks(strategy);
~~~

## Windows

Flink具有非常富有表现力的窗口语义。

在本节中，您将学习：

* 如何使用Windows来计算无界流的聚合
* Flink支持哪些类型的windows
* 如何实现一个窗口聚合的`DataStream`程序

### Introduction

在进行流处理时，很自然地想要对流的有界子集计算聚合分析，以便回答此类问题：

* 每分钟的`page view`
* 每个用户每周的`session`数
* 每个传感器每分钟的最高温度

使用Flink计算窗口分析依赖于两个主要的抽象:将事件分配给窗口的`Window Assigners`(必要时创建新的窗口对象)
和应用于分配给窗口的事件的`Window Functions`。

Flink的`windowing API`也有`触发器(Triggers)`和`驱逐器(Evictors)`的概念，前者决定何时调用`window function`，后者可以删除窗口中收集的元素。

在其基本形式中，您可以像这样将窗口应用于`keyed stream`：

~~~
stream
    .keyBy(<key selector>)
    .window(<window assigner>)
    .reduce|aggregate|process(<window function>);
~~~

您也可以对`non-keyed streams`使用窗口，但请记住，在这种情况下，处理将`不会并行执行`：

~~~
stream
    .windowAll(<window assigner>)
    .reduce|aggregate|process(<window function>);
~~~

### Window Assigners

Flink有几种内置的`window assigners`类型，如下所示

![](images/streaming-analytics/window-assigners.svg)

这些`window assigners`可能用于的一些示例以及如何使用：

* Tumbling time windows（滚动时间窗口）
    * 每分钟页面浏览量
    * TumblingEventTimeWindows.of(Time.minutes(1))
* Sliding time windows（滑动时间窗口）
    * 每分钟的页面浏览量，每10秒计算一次
    * SlidingEventTimeWindows.of(Time.minutes(1), Time.seconds(10))
* Session windows（会话窗口）
    * 每个会话的页面浏览量，其中会话之间至少30分钟的间隔
    * EventTimeSessionWindows.withGap(Time.minutes(30))

可以使用`Time.milliseconds(n)`, `Time.seconds(n)`, `Time.minutes(n)`, `Time.hours(n)`和`Time.days(n)`中的一个指定持续时间。

基于时间的`window assigners`(包括会话窗口)有`event time`和`processing time`两种类型。 这两种时间窗口之间存在着重要的取舍。

对于处理时间窗口，您必须接受这些限制：

* 不能正确处理历史数据
* 不能正确处理乱序数据
* 结果是不确定的

但使用处理时间窗口，具有`较低延迟`的优点。

<span style="color:orange; ">注意：
<br/>当使用`基于计数的窗口`时这些窗口在`批处理完成之前`不会触发。没有`超时`和`处理部分窗口`的选项，除非您使用自定义触发器自己实现该行为。
<br/>
<br/>`global window assigner`将每个`具有相同key`的事件分配给相同的全局窗口。这只有在您要使用`自定义触发器`
执行自己的`自定义窗口`时才有用。
在许多情况下，这似乎很有用，但您最好使用[Event-driven Applications](event-driven-applications.md)
中描述的`ProcessFunction`。
</span>

### Window Functions

对于如何处理窗口的内容，您有三个基本选项

* 1.作为批处理，使用`ProcessWindowFunction`，该函数将被传递一个带有窗口内容的`Iterable`
* 2.递增地，在每个事件分配给窗口时调用`ReduceFunction`或`AggregateFunction`
* 3.或者两者的结合，其中`ReduceFunction`或`AggregateFunction`的`预聚合结果`，在窗口被触发时提供给`ProcessWindowFunction`。

下面是`方法1`和`方法3`的例子。每个实现在1分钟事件时间窗口内从每个传感器找到峰值，并产生包含(key, end- window-timestamp,
max value)的元组流。

#### ProcessWindowFunction Example

~~~
DataStream<SensorReading> input = ...;

input
    .keyBy(x -> x.key)
    .window(TumblingEventTimeWindows.of(Time.minutes(1)))
    .process(new MyWastefulMax());

public static class MyWastefulMax extends ProcessWindowFunction<
        SensorReading,                  // input type
        Tuple3<String, Long, Integer>,  // output type
        String,                         // key type
        TimeWindow> {                   // window type
    
    @Override
    public void process(
            String key,
            Context context, 
            Iterable<SensorReading> events,
            Collector<Tuple3<String, Long, Integer>> out) {

        int max = 0;
        for (SensorReading event : events) {
            max = Math.max(event.value, max);
        }
        out.collect(Tuple3.of(key, context.window().getEnd(), max));
    }
}
~~~

在这个实现中有几点需要注意：

* 所有分配给窗口的事件都必须在`keyed Flink state`下进行缓冲，直到触发窗口。这可能相当昂贵的。
* 我们的`ProcessWindowFunction`被传递了一个`Context`对象，这个对象包含了关于窗口的信息。它的接口是这样的：

~~~
public abstract class Context implements java.io.Serializable {
    public abstract W window();
    
    public abstract long currentProcessingTime();
    public abstract long currentWatermark();

    public abstract KeyedStateStore windowState();
    public abstract KeyedStateStore globalState();
}
~~~

`windowState`和`globalState`可以用来存储该key的`所有窗口`的`per-key`、`per-window`或`global per-key`信息。
这可能是有用的，例如，如果您想记录有关`当前窗口`的一些内容，并在处理`后续窗口`时使用它。

#### Incremental Aggregation Example

~~~
DataStream<SensorReading> input = ...;

input
    .keyBy(x -> x.key)
    .window(TumblingEventTimeWindows.of(Time.minutes(1)))
    .reduce(new MyReducingMax(), new MyWindowFunction());

private static class MyReducingMax implements ReduceFunction<SensorReading> {
    public SensorReading reduce(SensorReading r1, SensorReading r2) {
        return r1.value() > r2.value() ? r1 : r2;
    }
}

private static class MyWindowFunction extends ProcessWindowFunction<
    SensorReading, Tuple3<String, Long, SensorReading>, String, TimeWindow> {

    @Override
    public void process(
            String key,
            Context context,
            Iterable<SensorReading> maxReading,
            Collector<Tuple3<String, Long, SensorReading>> out) {

        SensorReading max = maxReading.iterator().next();
        out.collect(Tuple3.of(key, context.window().getEnd(), max));
    }
}
~~~

<span style="color:orange; ">注意，`Iterable<SensorReading>`将只包含一个读数（`MyReducingMax`计算的预聚合最大值）。</span>

### Late Events

默认情况下，当使用`事件时间窗口`时，`延迟的事件`将被`丢弃`。窗口API有两个选项，可以让您对此进行更多的控制。

1.您可以使用一种称为`Side Outputs`的机制，将将要丢弃的事件收集到备用输出流中。这里有一个例子：

~~~
OutputTag<Event> lateTag = new OutputTag<Event>("late"){};

SingleOutputStreamOperator<Event> result = stream
    .keyBy(...)
    .window(...)
    .sideOutputLateData(lateTag)
    .process(...);
  
DataStream<Event> lateStream = result.getSideOutput(lateTag);
~~~

2.您还可以指定`允许延迟`的间隔，在此期间，`延迟事件`将继续分配给`适当的窗口`(其`state`将被保留)。
默认情况下，每个延迟事件将导致再次调用窗口函数(有时称为`late firing`)。

默认情况下，`允许延迟`的时间为`0`。换句话说，`watermark`后面的元素被丢弃(或发送到`side output`)。

例如：

~~~
stream
    .keyBy(...)
    .window(...)
    .allowedLateness(Time.seconds(10))
    .process(...);
~~~

当`允许延迟`的时间大于`0`时，只有那些`延迟到将被丢弃的事件`才会被发送到`side output`(如果`side output`已配置的话)。

### Surprises

Flink的`windowing API`的某些方面可能不像您期望的那样运行。根据`flink-user mailing list`
里和其他地方经常被问及的问题，这里有一些关于窗口的事实可能会让你感到惊讶。

#### Sliding Windows Make Copies

`Sliding window assigners`可以创建许多窗口对象，并将`每个事件`复制到每个相关的窗口中。
例如，如果`每15分钟`有一个`24小时长度`的滑动窗口，则每个事件将被复制到`4 * 24 = 96`个窗口中。

#### Time Windows are Aligned to the Epoch

仅仅因为您使用的是`一个小时`的`处理时间窗口`，并在12:05开始运行应用程序，并不意味着第一个窗口将在1:05关闭。第一个窗口将持续55分钟，1点关闭。

但是请注意，滚动和滑动`window assigners`可以接受一个可选的偏移参数，该参数可用于更改窗口的`对齐方式`。

#### Windows Can Follow Windows

例如，这样做是有效的：

~~~
stream
    .keyBy(t -> t.key)
    .window(<window assigner>)
    .reduce(<reduce function>)
    .windowAll(<same window assigner>)
    .reduce(<same reduce function>);
~~~

您可能期望`Flink runtime`足够聪明，可以为您执行这种并行预聚合(如果您使用的是`ReduceFunction`或`AggregateFunction`)
，但事实并非如此。

这样做的原因是，时间窗口产生的事件是根据`窗口结束时间`分配时间戳的。
因此，例如，由`一个小时长的窗口`产生的`所有事件`都将具有标记`一小时结束的时间戳`。
`任何后续窗口`在消费这些事件时，它的`持续时间`应该与前一个窗口的`相同`，或者是前一个窗口的`倍数`。

#### No Results for Empty TimeWindows

<span style="color:orange; ">
只有当事件分配给它们时，才会创建窗口。因此，如果在给定的时间范围内没有事件，则不会报告任何结果。</span>

#### Late Events Can Cause Late Merges

`Session windows`是基于可以`merge`的窗口的抽象。<span style="color:orange; ">每个元素最初被分配到一个新窗口</span>
，之后，只要它们之间的间隙足够小，就合并窗口。
通过这种方式，`延迟的事件`可以缩小两个先前独立会话之间的差距，从而产生`延迟的合并`。

## Hands-on

本节附带的实践练习是[Hourly Tips Exercise](https://github.com/apache/flink-training/blob/release-1.17//hourly-tips)。

## Further Reading

* [Timely Stream Processing]
* [Windows]
