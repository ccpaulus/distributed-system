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

* 1.作为批处理，使用`ProcessWindowFunction`，该函数将传递一个带有窗口内容的`Iterable`
* 2.增量地，在每个事件分配给窗口时调用`ReduceFunction`或`AggregateFunction`
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

* 所有分配给窗口的事件都必须在键控Flink状态下进行缓冲，直到触发窗口。这可能相当昂贵。
* 我们的`ProcessWindowFunction`被传递了一个Context对象，它包含了关于窗口的信息。它的界面是这样的

~~~
public abstract class Context implements java.io.Serializable {
    public abstract W window();
    
    public abstract long currentProcessingTime();
    public abstract long currentWatermark();

    public abstract KeyedStateStore windowState();
    public abstract KeyedStateStore globalState();
}
~~~

`windowState`和`globalState`是您可以存储该key的`所有窗口`的每个key、每个window或全局的每个key信息的位置。
这可能是有用的，例如，如果您想记录有关当前窗口的一些内容，并在处理后续窗口时使用它。




