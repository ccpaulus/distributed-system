# Flink DataStream API 编程指南

Flink 中的 DataStream 程序是对数据流（例如过滤、更新状态、定义窗口、聚合）进行转换的常规程序。数据流的起始是从各种源（例如消息队列、套接字流、文件）创建的。结果通过
sink 返回，例如可以将数据写入文件或标准输出（例如命令行终端）。Flink 程序可以在各种上下文中运行，可以独立运行，也可以嵌入到其它程序中。任务执行可以运行在本地
JVM 中，也可以运行在多台机器的集群上。

Flink 中的 DataStream 程序是对数据流（例如过滤、更新状态、定义窗口、聚合）进行转换的常规程序。数据流的起始是从各种源（例如消息队列、套接字流、文件）创建的。结果通过
sink 返回，例如可以将数据写入文件或标准输出（例如命令行终端）。Flink 程序可以在各种上下文中运行，可以独立运行，也可以嵌入到其它程序中。任务执行可以运行在本地
JVM 中，也可以运行在多台机器的集群上。

## DataStream 是什么?

DataStream API 得名于特殊的 DataStream 类，该类用于表示 Flink 程序中的数据集合。你可以认为
它们是可以包含重复项的不可变数据集合。这些数据可以是有界（有限）的，也可以是无界（无限）的，但用于处理它们的API是相同的。

DataStream 在用法上类似于常规的 Java 集合，但在某些关键方面却大不相同。它们是不可变的，这意味着一旦它们被创建，你就不能添加或删除元素。你也不能简单地察看内部元素，而只能使用
DataStream API 操作来处理它们，DataStream API 操作也叫作转换（transformation）。

你可以通过在 Flink 程序中添加 source 创建一个初始的 DataStream。然后，你可以基于 DataStream 派生新的流，并使用 map、filter 等
API 方法把 DataStream 和派生的流连接在一起。

## Flink 程序剖析

Flink 程序看起来像一个转换 DataStream 的常规程序。每个程序由相同的基本部分组成：

1. 获取一个执行环境（execution environment）；
2. 加载/创建初始数据；
3. 指定数据相关的转换；
4. 指定计算结果的存储位置；
5. 触发程序执行。

All Flink Scala APIs are deprecated and will be removed in a future Flink version. You can still build your application
in Scala, but you should move to the Java version of either the DataStream and/or Table API.

现在我们将对这些步骤逐一进行概述，更多细节请参考相关章节。请注意，Java DataStream API 的所有核心类都可以在
org.apache.flink.streaming.api 中找到。

StreamExecutionEnvironment 是所有 Flink 程序的基础。你可以使用 StreamExecutionEnvironment 的如下静态方法获取
StreamExecutionEnvironment：

~~~
getExecutionEnvironment();

createLocalEnvironment();

createRemoteEnvironment(String host, int port, String... jarFiles);
~~~

通常，你只需要使用 getExecutionEnvironment() 即可，因为该方法会根据上下文做正确的处理：如果你在 IDE 中执行你的程序或将其作为一般的
Java 程序执行，那么它将创建一个本地环境，该环境将在你的本地机器上执行你的程序。如果你基于程序创建了一个 JAR
文件，并通过命令行运行它，Flink 集群管理器将执行程序的 main 方法，同时 getExecutionEnvironment() 方法会返回一个执行环境以在集群上执行你的程序。

为了指定 data sources，执行环境提供了一些方法，支持使用各种方法从文件中读取数据：你可以直接逐行读取数据，像读 CSV
文件一样，或使用任何第三方提供的 source。如果你只是将一个文本文件作为一个行的序列来读取，那么可以使用：

~~~
final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

DataStream<String> text = env.readTextFile("file:///path/to/file");
~~~

这将生成一个 DataStream，然后你可以在上面应用转换（transformation）来创建新的派生 DataStream。

你可以调用 DataStream 上具有转换功能的方法来应用转换。例如，一个 map 的转换如下所示：

~~~
DataStream<String> input = ...;

DataStream<Integer> parsed = input.map(new MapFunction<String, Integer>() {
    @Override
    public Integer map(String value) {
        return Integer.parseInt(value);
    }
});
~~~

这将通过把原始集合中的每一个字符串转换为一个整数来创建一个新的 DataStream。

一旦你有了包含最终结果的 DataStream，你就可以通过创建 sink 把它写到外部系统。下面是一些用于创建 sink 的示例方法：

~~~
writeAsText(String path);

print();
~~~

一旦指定了完整的程序，需要调用 StreamExecutionEnvironment 的 execute() 方法来**触发程序执行**。根据 ExecutionEnvironment
的类型，执行会在你的本地机器上触发，或将你的程序提交到某个集群上执行。

execute() 方法将等待作业完成，然后返回一个 JobExecutionResult，其中包含执行时间和累加器结果。

如果不想等待作业完成，可以通过调用 StreamExecutionEnvironment 的 executeAsync() 方法来触发作业异步执行。它会返回一个
JobClient，你可以通过它与刚刚提交的作业进行通信。如下是使用 executeAsync() 实现 execute() 语义的示例。

~~~
final JobClient jobClient = env.executeAsync();

final JobExecutionResult jobExecutionResult = jobClient.getJobExecutionResult().get();
~~~

关于程序执行的最后一部分对于理解何时以及如何执行 Flink 算子是至关重要的。所有 Flink 程序都是延迟执行的：当程序的 main
方法被执行时，数据加载和转换不会直接发生。相反，每个算子都被创建并添加到 dataflow 形成的有向图。当执行被执行环境的 execute()
方法显示地触发时，这些算子才会真正执行。程序是在本地执行还是在集群上执行取决于执行环境的类型。

延迟计算允许你构建复杂的程序，Flink 会将其作为一个整体的计划单元来执行。

## 示例程序

如下是一个完整的、可运行的程序示例，它是基于流窗口的单词统计应用程序，计算 5 秒窗口内来自 Web 套接字的单词数。你可以复制并粘贴代码以在本地运行。

~~~
import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.util.Collector;

public class WindowWordCount {

    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        DataStream<Tuple2<String, Integer>> dataStream = env
                .socketTextStream("localhost", 9999)
                .flatMap(new Splitter())
                .keyBy(value -> value.f0)
                .window(TumblingProcessingTimeWindows.of(Time.seconds(5)))
                .sum(1);

        dataStream.print();

        env.execute("Window WordCount");
    }

    public static class Splitter implements FlatMapFunction<String, Tuple2<String, Integer>> {
        @Override
        public void flatMap(String sentence, Collector<Tuple2<String, Integer>> out) throws Exception {
            for (String word: sentence.split(" ")) {
                out.collect(new Tuple2<String, Integer>(word, 1));
            }
        }
    }

}
~~~

要运行示例程序，首先从终端使用 netcat 启动输入流：

~~~
nc -lk 9999
~~~

只需输入一些单词，然后按回车键即可传入新单词。这些将作为单词统计程序的输入。如果想查看大于 1 的计数，在 5
秒内重复输入相同的单词即可（如果无法快速输入，则可以将窗口大小从 5 秒增加 ☺）。

## Data Sources

Source 是你的程序从中读取其输入的地方。你可以用 StreamExecutionEnvironment.addSource(sourceFunction) 将一个 source
关联到你的程序。Flink 自带了许多预先实现的 source functions，不过你仍然可以通过实现 SourceFunction 接口编写自定义的非并行
source，也可以通过实现 ParallelSourceFunction 接口或者继承 RichParallelSourceFunction 类编写自定义的并行 sources。

通过 StreamExecutionEnvironment 可以访问多种预定义的 stream source：

基于文件：

* readTextFile(path) - 读取文本文件，例如遵守 TextInputFormat 规范的文件，逐行读取并将它们作为字符串返回。
* readFile(fileInputFormat, path) - 按照指定的文件输入格式读取（一次）文件。
* readFile(fileInputFormat, path, watchType, interval, pathFilter, typeInfo) - 这是前两个方法内部调用的方法。它基于给定的
  fileInputFormat 读取路径 path 上的文件。根据提供的 watchType 的不同，source 可能定期（每 interval 毫秒）监控路径上的新数据（watchType
  为 FileProcessingMode.PROCESS_CONTINUOUSLY），或者处理一次当前路径中的数据然后退出（watchType 为
  FileProcessingMode.PROCESS_ONCE)。使用 pathFilter，用户可以进一步排除正在处理的文件。

  <br/>_实现：_
  <br/>在底层，Flink 将文件读取过程拆分为两个子任务，即 目录监控 和
  数据读取。每个子任务都由一个单独的实体实现。监控由单个非并行（并行度 =
  1）任务实现，而读取由多个并行运行的任务执行。后者的并行度和作业的并行度相等。单个监控任务的作用是扫描目录（定期或仅扫描一次，取决于
  watchType），找到要处理的文件，将它们划分为 分片，并将这些分片分配给下游 reader。Reader 是将实际获取数据的角色。每个分片只能被一个
  reader 读取，而一个 reader 可以一个一个地读取多个分片。

  <br/>__重要提示：_
    1. 如果 watchType 设置为 FileProcessingMode.PROCESS_CONTINUOUSLY，当一个文件被修改时，它的内容会被完全重新处理。这可能会打破
       “精确一次” 的语义，因为在文件末尾追加数据将导致重新处理文件的所有内容。
    2. 如果 watchType 设置为 FileProcessingMode.PROCESS_ONCE，source 扫描一次路径然后退出，无需等待 reader
       读完文件内容。当然，reader
       会继续读取数据，直到所有文件内容都读完。关闭 source 会导致在那之后不再有检查点。这可能会导致节点故障后恢复速度变慢，因为作业将从最后一个检查点恢复读取。

基于套接字：

* socketTextStream - 从套接字读取。元素可以由分隔符分隔。

基于集合：

* fromCollection(Collection) - 从 Java Java.util.Collection 创建数据流。集合中的所有元素必须属于同一类型。
* fromCollection(Iterator, Class) - 从迭代器创建数据流。class 参数指定迭代器返回元素的数据类型。
* fromElements(T ...) - 从给定的对象序列中创建数据流。所有的对象必须属于同一类型。
* fromParallelCollection(SplittableIterator, Class) - 从迭代器并行创建数据流。class 参数指定迭代器返回元素的数据类型。
* generateSequence(from, to) - 基于给定间隔内的数字序列并行生成数据流。

自定义：

* addSource - 关联一个新的 source function。例如，你可以使用 addSource(new FlinkKafkaConsumer<>(...)) 来从 Apache Kafka
  获取数据。更多详细信息见[连接器]()。

## DataStream Transformations

有关可用 stream 转换（transformation）的概述，请参阅[算子]()。

## Data Sinks

Data sinks 使用 DataStream 并将它们转发到文件、套接字、外部系统或打印它们。Flink 自带了多种内置的输出格式，这些格式相关的实现封装在
DataStreams 的算子里：

* writeAsText() / TextOutputFormat - 将元素按行写成字符串。通过调用每个元素的 toString() 方法获得字符串。
* writeAsCsv(...) / CsvOutputFormat - 将元组写成逗号分隔值文件。行和字段的分隔符是可配置的。每个字段的值来自对象的
  toString() 方法。
* print() / printToErr() - 在标准输出/标准错误流上打印每个元素的 toString() 值。 可选地，可以提供一个前缀（msg）附加到输出。这有助于区分不同的
  print 调用。如果并行度大于1，输出结果将附带输出任务标识符的前缀。
* writeUsingOutputFormat() / FileOutputFormat - 自定义文件输出的方法和基类。支持自定义 object 到 byte 的转换。
* writeToSocket - 根据 SerializationSchema 将元素写入套接字。
* addSink - 调用自定义 sink function。Flink 捆绑了连接到其他系统（例如 Apache Kafka）的连接器，这些连接器被实现为 sink
  functions。

注意，DataStream 的 write*() 方法主要用于调试目的。它们不参与 Flink 的 checkpointing，这意味着这些函数通常具有至少有一次语义。刷新到目标系统的数据取决于
OutputFormat 的实现。这意味着并非所有发送到 OutputFormat 的元素都会立即显示在目标系统中。此外，在失败的情况下，这些记录可能会丢失。

为了将流可靠地、精准一次地传输到文件系统中，请使用 FileSink。此外，通过 .addSink(...) 方法调用的自定义实现也可以参与 Flink 的
checkpointing，以实现精准一次的语义。

## Iterations

Iterative streaming 程序实现了 setp function 并将其嵌入到 IterativeStream 。由于 DataStream
程序可能永远不会完成，因此没有最大迭代次数。相反，你需要指定流的哪一部分反馈给迭代，哪一部分使用旁路输出或过滤器转发到下游。这里，我们展示了一个使用过滤器的示例。首先，我们定义一个
IterativeStream

~~~
IterativeStream<Integer> iteration = input.iterate();
~~~

然后，我们使用一系列转换（这里是一个简单的 map 转换）指定将在循环内执行的逻辑

~~~
DataStream<Integer> iterationBody = iteration.map(/* this is executed many times */);
~~~

要关闭迭代并定义迭代尾部，请调用 IterativeStream 的 closeWith(feedbackStream) 方法。提供给 closeWith 函数的 DataStream
将反馈给迭代头。一种常见的模式是使用过滤器将反馈的流部分和向前传播的流部分分开。例如，这些过滤器可以定义“终止”逻辑，其中允许元素向下游传播而不是被反馈。

~~~
iteration.closeWith(iterationBody.filter(/* one part of the stream */));
DataStream<Integer> output = iterationBody.filter(/* some other part of the stream */);
~~~

例如，下面的程序从一系列整数中连续减去 1，直到它们达到零：

~~~
DataStream<Long> someIntegers = env.generateSequence(0, 1000);

IterativeStream<Long> iteration = someIntegers.iterate();

DataStream<Long> minusOne = iteration.map(new MapFunction<Long, Long>() {
  @Override
  public Long map(Long value) throws Exception {
    return value - 1 ;
  }
});

DataStream<Long> stillGreaterThanZero = minusOne.filter(new FilterFunction<Long>() {
  @Override
  public boolean filter(Long value) throws Exception {
    return (value > 0);
  }
});

iteration.closeWith(stillGreaterThanZero);

DataStream<Long> lessThanZero = minusOne.filter(new FilterFunction<Long>() {
  @Override
  public boolean filter(Long value) throws Exception {
    return (value <= 0);
  }
});
~~~

## 执行参数

StreamExecutionEnvironment 包含了 ExecutionConfig，它允许在运行时设置作业特定的配置值。

大多数参数的说明可参考[执行配置]。这些参数特别适用于 DataStream API：

* setAutoWatermarkInterval(long milliseconds)：设置自动发送 watermark 的时间间隔。你可以使用 long
  getAutoWatermarkInterval() 获取当前配置值。

### 容错

[State & Checkpointing] 描述了如何启用和配置 Flink 的 checkpointing 机制。

### 控制延迟

默认情况下，元素不会在网络上一一传输（这会导致不必要的网络传输），而是被缓冲。缓冲区的大小（实际在机器之间传输）可以在 Flink
配置文件中设置。虽然此方法有利于优化吞吐量，但当输入流不够快时，它可能会导致延迟问题。要控制吞吐量和延迟，你可以调用执行环境（或单个算子）的
env.setBufferTimeout(timeoutMillis) 方法来设置缓冲区填满的最长等待时间。超过此时间后，即使缓冲区没有未满，也会被自动发送。超时时间的默认值为
100 毫秒。

~~~
LocalStreamEnvironment env = StreamExecutionEnvironment.createLocalEnvironment();
env.setBufferTimeout(timeoutMillis);

env.generateSequence(1,10).map(new MyMapper()).setBufferTimeout(timeoutMillis);
~~~

为了最大限度地提高吞吐量，设置 setBufferTimeout(-1) 来删除超时，这样缓冲区仅在它们已满时才会被刷新。要最小化延迟，请将超时设置为接近
0 的值（例如 5 或 10 毫秒）。应避免超时为 0 的缓冲区，因为它会导致严重的性能下降。

## 调试

在分布式集群中运行流程序之前，最好确保实现的算法能按预期工作。因此，实现数据分析程序通常是一个检查结果、调试和改进的增量过程。

Flink 通过提供 IDE 内本地调试、注入测试数据和收集结果数据的特性大大简化了数据分析程序的开发过程。本节给出了一些如何简化
Flink 程序开发的提示。

### 本地执行环境

LocalStreamEnvironment 在创建它的同一个 JVM 进程中启动 Flink 系统。如果你从 IDE 启动 LocalEnvironment，则可以在代码中设置断点并轻松调试程序。
一个 LocalEnvironment 的创建和使用如下：

~~~
final StreamExecutionEnvironment env = StreamExecutionEnvironment.createLocalEnvironment();

DataStream<String> lines = env.addSource(/* some source */);
// 构建你的程序

env.execute();
~~~

### 集合 Data Sources

Flink 提供了由 Java 集合支持的特殊 data sources 以简化测试。一旦程序通过测试，sources 和 sinks 可以很容易地被从外部系统读取/写入到外部系统的
sources 和 sinks 替换。

可以按如下方式使用集合 Data Sources：

~~~
final StreamExecutionEnvironment env = StreamExecutionEnvironment.createLocalEnvironment();

// 从元素列表创建一个 DataStream
DataStream<Integer> myInts = env.fromElements(1, 2, 3, 4, 5);

// 从任何 Java 集合创建一个 DataStream
List<Tuple2<String, Integer>> data = ...
DataStream<Tuple2<String, Integer>> myTuples = env.fromCollection(data);

// 从迭代器创建一个 DataStream
Iterator<Long> longIt = ...
DataStream<Long> myLongs = env.fromCollection(longIt, Long.class);
~~~

**注意：** 目前，集合 data source 要求数据类型和迭代器实现 Serializable。此外，集合 data sources 不能并行执行（parallelism =
1）。

### 迭代器 Data Sink

Flink 还提供了一个 sink 来收集 DataStream 的结果，它用于测试和调试目的。可以按以下方式使用。

~~~
DataStream<Tuple2<String, Integer>> myResult = ...
Iterator<Tuple2<String, Integer>> myOutput = myResult.collectAsync();
~~~

## 接下来？

* [算子]()：可用算子的使用指南。
* [Event Time]()：Flink 中时间概念的介绍。
* [状态 & 容错]()：如何开发有状态应用程序的讲解。
* [连接器]()：所有可用输入和输出连接器的描述。

