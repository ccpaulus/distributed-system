# Event-driven Applications

## Process Functions

### Introduction

`ProcessFunction`将事件处理与`timers`和`state`相结合，使其成为流式处理应用程序的强大构建块。
这是使用Flink创建`事件驱动应用程序（event-driven applications）`的基础。它与`RichFlatMapFunction`非常相似，但增加了`timers`。

### Example

如果您在`Streaming Analytics`培训中做过实践练习，您将记得它使用`TumblingEventTimeWindow`
来计算每个驾驶员在每个小时内的`tips`之和，如下所示：

~~~
// compute the sum of the tips per hour for each driver
DataStream<Tuple3<Long, Long, Float>> hourlyTips = fares
        .keyBy((TaxiFare fare) -> fare.driverId)
        .window(TumblingEventTimeWindows.of(Time.hours(1)))
        .process(new AddTips());
~~~

使用`KeyedProcessFunction`做同样的事情相当简单，而且具有教育意义。让我们首先用下面的代码替换上面的代码：

~~~
// compute the sum of the tips per hour for each driver
DataStream<Tuple3<Long, Long, Float>> hourlyTips = fares
        .keyBy((TaxiFare fare) -> fare.driverId)
        .process(new PseudoWindow(Time.hours(1)));
~~~

在这个代码片段中，一个名为`PseudoWindow`的`KeyedProcessFunction`被应用于一个`keyed stream`，
其结果是一个`DataStream<Tuple3<Long, Long, Float>>`(这与使用Flink内置时间窗口的实现产生的流类型相同)。

`PseudoWindow`的大体结构如下：

~~~
// Compute the sum of the tips for each driver in hour-long windows.
// The keys are driverIds.
public static class PseudoWindow extends 
        KeyedProcessFunction<Long, TaxiFare, Tuple3<Long, Long, Float>> {

    private final long durationMsec;

    public PseudoWindow(Time duration) {
        this.durationMsec = duration.toMilliseconds();
    }

    @Override
    // Called once during initialization.
    public void open(Configuration conf) {
        . . .
    }

    @Override
    // Called as each fare arrives to be processed.
    public void processElement(
            TaxiFare fare,
            Context ctx,
            Collector<Tuple3<Long, Long, Float>> out) throws Exception {

        . . .
    }

    @Override
    // Called when the current watermark indicates that a window is now complete.
    public void onTimer(long timestamp, 
            OnTimerContext context, 
            Collector<Tuple3<Long, Long, Float>> out) throws Exception {

        . . .
    }
}
~~~

需要注意的事项：

* `ProcessFunctions`有几种类型，此处是一个`KeyedProcessFunction`
  ，但也有`CoProcessFunctions`, `BroadcastProcessFunctions`等。
* `KeyedProcessFunction`是`RichFunction`的一种。作为一个`RichFunction`，它可以访问处理`managed keyed state`所需的`open`
  和`getRuntimeContext`方法。
* 有两个回调要实现:`processElement`和`onTimer`。`processElement`在每个传入事件时被调用;`onTimer`当`timers`触发时被调用。
  `timers`可以是`event time`类型或`processing time`类型。`processElement`和`onTimer`都提供了一个上下文对象，
  该对象可用于与`TimerService`(以及其他事物)交互。这两个回调函数还传递了一个可用于发出结果的`Collector`。

#### The open() method

~~~
// Keyed, managed state, with an entry for each window, keyed by the window's end time.
// There is a separate MapState object for each driver.
private transient MapState<Long, Float> sumOfTips;

@Override
public void open(Configuration conf) {

    MapStateDescriptor<Long, Float> sumDesc =
            new MapStateDescriptor<>("sumOfTips", Long.class, Float.class);
    sumOfTips = getRuntimeContext().getMapState(sumDesc);
}
~~~

由于`票价事件`可能无序到达，因此有时需要在完成`计算前一小时的结果`之前处理一个小时的事件。
实际上，如果`watermarking`延迟比`窗口长度`长得多，那么可能有许多窗口同时打开，而不是只有两个。
这个实现通过使用`MapState`来支持这一点，`MapState`将`每个窗口结束的时间戳`映射到该窗口的`tips`之和。

#### The processElement() method

~~~
public void processElement(
        TaxiFare fare,
        Context ctx,
        Collector<Tuple3<Long, Long, Float>> out) throws Exception {

    long eventTime = fare.getEventTime();
    TimerService timerService = ctx.timerService();

    if (eventTime <= timerService.currentWatermark()) {
        // This event is late; its window has already been triggered.
    } else {
        // Round up eventTime to the end of the window containing this event.
        long endOfWindow = (eventTime - (eventTime % durationMsec) + durationMsec - 1);

        // Schedule a callback for when the window has been completed.
        timerService.registerEventTimeTimer(endOfWindow);

        // Add this fare's tip to the running total for that window.
        Float sum = sumOfTips.get(endOfWindow);
        if (sum == null) {
            sum = 0.0F;
        }
        sum += fare.tip;
        sumOfTips.put(endOfWindow, sum);
    }
}
~~~

需要注意的事项：

* 迟到的事件会发生什么?在`watermark`后面的事件(即延迟)正在被丢弃。如果您希望做得更好，请考虑使用`side output`，这将在下一节中进行解释。
* 本例使用`MapState`，其中`keys`是时间戳，并为相同的时间戳设置`Timer`。
  这是一个常见的模式；这使得在`timer`触发时查找相关信息变得`简单`和`高效`。

#### The onTimer() method

~~~
public void onTimer(
        long timestamp, 
        OnTimerContext context, 
        Collector<Tuple3<Long, Long, Float>> out) throws Exception {

    long driverId = context.getCurrentKey();
    // Look up the result for the hour that just ended.
    Float sumOfTips = this.sumOfTips.get(timestamp);

    Tuple3<Long, Long, Float> result = Tuple3.of(driverId, timestamp, sumOfTips);
    out.collect(result);
    this.sumOfTips.remove(timestamp);
}
~~~

观察结果：

* 传递给`onTimer`的`OnTimerContext context`可以用来确定当前`key`。
* 当`current watermark`达到每小时结束时，`PseudoWindow`被触发，此时调用`onTimer`。这个`onTimer`方法会从`sumOfTips`
  中删除了相关的条目，这会导致无法容纳延迟事件。这相当于在使用Flink的时间窗口时将`allowedLateness`设置为`0`。

### Performance Considerations

Flink提供了针对`RocksDB`优化的`MapState`和`ListState`类型。
尽可能地，应该使用这些对象来代替保存某种集合的`ValueState`对象。
`RocksDB state backend`可以在不经过`(反)序列化`的情况下追加到`ListState`；
而对于`MapState`，每个`key/value`对是一个单独的`RocksDB对象`，因此`MapState`可以高效地访问和更新。

## Side Outputs

### Introduction

有几个很好的理由可以让一个Flink`operator`有多个输出流，如：

* 异常
* 格式错误的事件
* 延迟事件
* 操作警报，例如与外部服务的连接超时

`Side outputs`是一种方便的方法。除了错误报告之外，`side outputs`也是实现流的`N路（n-way）`分割的好方法。

### Example

现在，您可以对上一节中忽略的后期事件进行处理。

`side output`通道与`OutputTag<T>`相关联。这些`tags`具有与`side output`的`DataStream`类型对应的`泛型类型`，并且它们具有名称。

~~~
private static final OutputTag<TaxiFare> lateFares = new OutputTag<TaxiFare>("lateFares") {};
~~~

上面显示的静态的`OutputTag<TaxiFare>`，可以在`PseudoWindow`的`processElement`方法中发出延迟事件时，引用`lateFares`：

~~~
if (eventTime <= timerService.currentWatermark()) {
    // This event is late; its window has already been triggered.
    ctx.output(lateFares, fare);
} else {
    . . .
}
~~~

也可以，在作业的`main`方法中，从此`side output`访问流时，引用`lateFares`：

~~~
// compute the sum of the tips per hour for each driver
SingleOutputStreamOperator hourlyTips = fares
        .keyBy((TaxiFare fare) -> fare.driverId)
        .process(new PseudoWindow(Time.hours(1)));

hourlyTips.getSideOutput(lateFares).print();
~~~

或者，您可以使用两个具有相同名称的`OutputTags`来引用相同的`side output`，但是如果您这样做，它们必须具有`相同的类型`。

## Closing Remarks

在这个例子中，您已经看到了如何使用`ProcessFunction`来重新实现一个简单的时间窗口。
当然，如果Flink的`内置windowing API`满足了您的需求，那么请务必使用它。
但是，如果你发现自己正在考虑用Flink的`windows`做一些扭曲的事情，不要害怕滚动你自己的`windows`。

此外，`ProcessFunctions`对于计算分析之外的许多其他用例也很有用。下面的`hands-on`练习提供了一个完全不同的例子。

`ProcessFunctions`的另一个常见用例是过期陈旧的`state`。
如果您回想一下[Rides and Fares Exercise](https://github.com/apache/flink-training/blob/release-1.17//rides-and-fares)，
其中使用`RichCoFlatMapFunction`来计算一个简单的`join`，示例解决方案假设`TaxiRides`和`TaxiFares`
是完美匹配的，即`每个rideId都是一对一的`。
如果一个事件丢失了，相同`rideId`的另一个事件将永远保留在`state`中。
这可以通过`KeyedCoProcessFunction`实现，并且可以使用`timer`来检测和清除任何陈旧的`state`。

## Hands-on

本节附带的实践练习是[Long Ride Alerts Exercise](https://github.com/apache/flink-training/blob/release-1.17//long-ride-alerts)。

## Further Reading

* [ProcessFunction]
* [Side Outputs]