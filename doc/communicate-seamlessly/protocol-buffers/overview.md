# 概述

Protocol Buffers 提供了一种与语言无关、与平台无关的可扩展机制，用于以`向前兼容 和 向后兼容`的方式序列化结构化数据。
它类似于 JSON，只是更小更快，并且生成本地语言绑定。您只需定义一次数据的结构化方式，然后就可以使用`特殊生成的源代码`
轻松地`使用各种语言`将结构化数据写入和读取到各种数据流。

Protocol Buffers 由以下概念组合而成：

* `定义语言`（在 .proto 文件中创建）
* proto 编译器为 与数据交互 而生成的`代码`
* 特定于语言的`运行时库`
* 写入文件（或通过网络连接发送）的数据的`序列化格式`。

## Protocol Buffers 解决了什么问题？

Protocol Buffers 为大小不超过`几兆字节`的`类型化、结构化数据`的`数据包（packets）`提供了一种序列化格式。
这种格式既适合短期的网络流量，也适合长期的数据存储。可以使用新信息扩展 Protocol Buffers ，而不会使`现有数据无效`
或`要求更新代码`。

Protocol Buffers 是 Google 最常用的数据格式。它们广泛用于服务器间通信以及磁盘上数据的存档存储。
Protocol Buffers 的 _messages_ 和 _services_ 由工程师编写的 .proto 文件描述。

下面显示了一个示例消息：

~~~
message Person {
  optional string name = 1;
  optional int32 id = 2;
  optional string email = 3;
}
~~~

`proto 编译器`在 .proto 文件的构建时被调用，以生成各种编程语言的代码(本主题后面的[跨语言兼容性]()将介绍)，以操作相应的
protocol buffer。每个生成的类都包含`每个字段的访问函数`和`将整个结构序列化为原始字节的方法`
以及`将整个结构从原始字节解析的方法`。
下面展示了一个使用这些生成方法的示例：

~~~
Person john = Person.newBuilder()
    .setId(1234)
    .setName("John Doe")
    .setEmail("jdoe@example.com")
    .build();
output = new FileOutputStream(args[0]);
john.writeTo(output);
~~~

由于 Protocol Buffers 在 Google 的所有服务中广泛使用，并且其中的数据可能会持续一段时间，因此保持向后兼容性至关重要。
Protocol Buffers 允许在不破坏现有服务的情况下，无缝支持任何的更改，包括 添加新字段 和 删除现有字段。
有关此主题的更多信息，请参阅本主题后面的[更新 Proto 定义而不更新代码]()。

## 使用 Protocol Buffers 的好处是什么？

Protocol Buffers 适用于 以`与语言无关、与平台无关、可扩展`的方式 序列化 `结构化的、类似记录的`类型化数据 的情况。
它们最常用于 `定义通信协议(与 gRPC 一起)` 和 `数据存储`。

使用 Protocol Buffers 的一些优点包括：

* 紧凑数据存储
* 快速解析
* 支持多种编程语言
* 通过自动生成类优化的功能

### 跨语言的兼容性

`任何受支持的`编程语言所编写的代码都可以读取相同的消息。
您可以让一个平台上的 Java 程序从一个软件系统中采集数据，根据 `.proto`定义对其进行序列化，然后在另一个平台上运行的 Python
应用程序中从序列化的数据中提取特定的值。

以下语言直接在 Protocol Buffers 编译器（protoc）中得到支持：

* [C++]()
* [C#]()
* [Java]()
* [Kotlin]()
* [Objective-C]()
* [PHP]()
* [Python]()
* [Ruby]()

Google 支持以下语言，但项目源代码驻留在 GitHub 存储库中。 protoc 编译器使用这些语言的插件，来进行支持：

* [Dart]()
* [Go]()

其他语言不直接由 Google 支持，而是由其他 GitHub 项目支持。这些语言在 [Protocol Buffers 的第三方附加组件]()中有介绍。

### 跨项目的支持

通过在 `.proto` 文件中定义驻留在特定项目代码库之外的 `message` 类型，可以跨项目使用 Protocol Buffers 。
如果您定义的 `message` 类型或 枚举 预计将在您的直接团队之外`广泛使用（widely-used）`，那么您可以将它们放在它们自己的文件中，而不需要依赖关系。

在 Google 中`广泛使用`的两个 proto 定义示例是
[timestamp.proto](https://github.com/protocolbuffers/protobuf/blob/main/src/google/protobuf/timestamp.proto) 和
[status.proto](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) 。

### 更新 Proto 定义而不更新代码

`向后兼容`是软件产品的标准，但`向前兼容`则不太常见。只要在更新 `.proto` 定义时遵循一些[简单的实践]()
，旧代码就可以毫无问题地读取新消息，任何新添加的字段将被忽略；而被删除的字段将具有其默认值，并且被删除的重复字段将为空。
有关`重复字段`的信息，请参阅本主题后面的 [Protocol Buffers 定义语法]()。

新代码也将透明地读取旧消息。新字段将不会出现在旧消息中；此时，Protocol Buffers 会提供一个合理的默认值。

### 什么时候 Protocol Buffers 不适用？

Protocol Buffers 不适合所有数据。特别是以下场景：

* Protocol Buffers 倾向于假设整个消息可以一次加载到内存中，并且不大于对象图。对于超过几兆字节的数据，请考虑不同的解决方案;
  当处理较大的数据时，由于序列化的副本，您可能会有效地获得多个数据副本，这可能会导致内存使用出现惊人的峰值。
* 当 Protocol Buffers 序列化时，相同的数据可以有许多不同的二进制序列化。如果不完全解析两个消息，就不能比较它们是否相等。
* 消息不被压缩。虽然可以像压缩任何其他文件一样压缩消息，但是专用的压缩算法(如 JPE G和 PNG 使用的压缩算法)将为适当类型的数据生成更小的文件。
* 对于许多涉及大型多维浮点数数组的科学和工程应用，Protocol Buffers 消息在大小和速度上都不是最有效的。
  对于这些应用程序，[FITS]() 和类似格式的开销更小。
* 在科学计算中流行的非面向对象语言(如 Fortran 和 IDL)对 Protocol buffers 支持地不好。
* Protocol buffers 消息本身并不自描述它们的数据，但是它们有一个完全反射的模式（schema）来实现自描述。
  也就是说，如果不访问对应的 `.proto` 文件，就不能完全解释一个文件。
* Protocol buffers 不是任何组织的正式标准。在有法律或其他要求的环境需要基于某些标准，此时则不适用。

## 谁使用 Protocol buffers ？

许多项目使用 Protocol buffers，包括以下：

* [gRPC]()
* [Google Cloud]()
* [Envoy Proxy]()

## Protocol buffers 是如何工作的？

下图显示了如何使用 Protocol buffers 来处理数据。

![](images/protocol-buffers-concepts.png)

图1所示。Protocol buffers 工作流

Protocol buffers 生成的代码提供了从文件和流中检索数据、从数据中提取单个值、检查数据是否存在、将数据序列化回文件或流以及其他有用的功能的工具方法。

下面的代码示例向您展示了该流在 Java 中的示例。如前所述，这是一个 `.proto` 定义：

~~~
message Person {
  optional string name = 1;
  optional int32 id = 2;
  optional string email = 3;
}
~~~

编译这个 `.proto` 文件会创建一个 `Builder` 类，您可以使用它来创建新的实例，如下面的 Java 代码所示：

~~~
Person john = Person.newBuilder()
    .setId(1234)
    .setName("John Doe")
    .setEmail("jdoe@example.com")
    .build();
output = new FileOutputStream(args[0]);
john.writeTo(output);
~~~

然后，您可以使用 Protocol buffers 在其他语言(如 C++)中创建的方法对数据进行反序列化：

~~~
Person john;
fstream input(argv[1], ios::in | ios::binary);
john.ParseFromIstream(&input);
int id = john.id();
std::string name = john.name();
std::string email = john.email();
~~~

## Protocol buffers 定义语法

在定义 `.proto` 文件时，您可以指定字段是 `optional` 或 `repeated` (proto2 和 proto3)，或者将其设置为 proto3 中默认的隐式存在。
(将字段设置为 `required` 的选项，在 proto3 中不存在，在 proto2
中也强烈不鼓励使用。有关这方面的更多信息，请参阅[指定字段规则]()中的 “Required 是永久的”。)

在设置字段的 `可选性/重复性` 之后，需要指定数据类型。Protocol buffers 支持常用的基本数据类型，如 integers、booleans 和
floats。有关完整列表，请参见[标量值类型]()。

字段可以是：

* `message` 类型，以便您可以嵌套部分定义，例如用于重复数据集。
* `enum` 类型，因此可以指定要从中选择的一组值。
* `oneof` 类型，当消息有许多可选字段且最多同时设置一个字段时，可以使用该类型。
* `map` 类型，用于向定义中添加键值对。

在 proto2 中，消息允许扩展定义消息本身之外的字段。例如，protobuf 库的`内部消息模式`允许扩展自定义的、特殊用法的选项。

有关可用选项的更多信息，请参阅 [proto2]() 或 [proto3]() 的语言指南。

在设置可选性和字段类型之后，分配字段编号。字段编号不能被重新利用或重用。如果您删除一个字段，您应该保留其字段编号，以防止有人意外地重用该号码。

## 附加数据类型支持

Protocol buffers 支持许多标量值类型，包括既使用变长编码又使用固定大小的整数。您还可以通过定义消息来创建自己的复合数据类型，
这些消息本身就是您可以分配给字段的数据类型。除了简单值类型和复合值类型之外，还有几种公共类型。

### 公共类型：

* [Duration]() 是有符号的固定长度的时间，例如 42 秒。
* [Timestamp]() 是独立于时区和日历的时间点，如 2017-01-15T01:30:15.01Z。
* [Interval]() 是与时区和日历无关的时间间隔，如 2017-01-15T01:30:15.01Z - 2017-01-16T02:30:15.01Z。
* [Date]() 为整日历日期，如 2025-09-19。
* [DayOfWeek]() 是一周中的某一天，例如星期一。
* [TimeOfDay]() 是一天中的时间，如 10:42:23。
* [LatLng]() 是一对经纬度，如 纬度 37.386051 和 经度 -122.083855。
* [Money]() 是指有货币类型的货币数量，如 42 美元。
* [PostalAddress]() 是一个邮政地址，例如 1600 Amphitheatre Parkway Mountain View, CA 94043 USA。
* [Color]() 是 RGBA 色彩空间中的一种颜色。
* [Month]() 是一年中的某个月份，如 四月。

## 历史

要了解 Protocol buffers 项目的历史，请参阅 [Protocol buffers 的历史]()。

## Protocol buffers 开源哲学

Protocol buffers 是在 2008 年开源的，作为一种向 Google 外部的开发人员提供我们从内部获得的同样好处的方式。
我们通过定期更新语言来支持开源社区，因为我们做出了这些更改来支持我们的内部需求。
虽然我们接受来自外部开发人员的选择拉取请求，但我们不能总是优先考虑不符合谷歌特定需求的功能请求和错误修复。

## 开发者社区

要了解即将到来的 Protocol buffers 的变化，并与 protobuf 开发人员和用户联系，[请加入Google Group]()。

## 附加资源

* [Protocol Buffers GitHub](https://github.com/protocolbuffers/protobuf/)

