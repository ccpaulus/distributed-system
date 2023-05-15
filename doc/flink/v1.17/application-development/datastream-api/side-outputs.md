# 旁路输出

除了由 DataStream
操作产生的主要流之外，你还可以产生任意数量的旁路输出结果流。结果流中的数据类型不必与主要流中的数据类型相匹配，并且不同旁路输出的类型也可以不同。当你需要拆分数据流时，通常必须复制该数据流，然后从每个流中过滤掉不需要的数据，这个操作十分有用。

使用旁路输出时，首先需要定义用于标识旁路输出流的 OutputTag：

~~~
// 这需要是一个匿名的内部类，以便我们分析类型
OutputTag<String> outputTag = new OutputTag<String>("side-output") {};
~~~

注意 OutputTag 是如何根据旁路输出流所包含的元素类型进行类型化的。

可以通过以下方法将数据发送到旁路输出：

* [ProcessFunction]()
* [KeyedProcessFunction]()
* CoProcessFunction
* KeyedCoProcessFunction
* [ProcessWindowFunction]()
* ProcessAllWindowFunction

你可以使用在上述方法中向用户暴露的 Context 参数，将数据发送到由 OutputTag 标识的旁路输出。这是从 ProcessFunction
发送数据到旁路输出的示例：

~~~
DataStream<Integer> input = ...;

final OutputTag<String> outputTag = new OutputTag<String>("side-output"){};

SingleOutputStreamOperator<Integer> mainDataStream = input
  .process(new ProcessFunction<Integer, Integer>() {

      @Override
      public void processElement(
          Integer value,
          Context ctx,
          Collector<Integer> out) throws Exception {
        // 发送数据到主要的输出
        out.collect(value);

        // 发送数据到旁路输出
        ctx.output(outputTag, "sideout-" + String.valueOf(value));
      }
    });
~~~

你可以在 DataStream 运算结果上使用 getSideOutput(OutputTag) 方法获取旁路输出流。这将产生一个与旁路输出流结果类型一致的
DataStream：

Java

~~~
final OutputTag<String> outputTag = new OutputTag<String>("side-output"){};

SingleOutputStreamOperator<Integer> mainDataStream = ...;

DataStream<String> sideOutputStream = mainDataStream.getSideOutput(outputTag);
~~~

**Note**: If it produces side output, get_side_output(OutputTag) must be called in Python API. Otherwise, the result of
side output stream will be output into the main stream which is unexpected and may fail the job when the data types are
different.