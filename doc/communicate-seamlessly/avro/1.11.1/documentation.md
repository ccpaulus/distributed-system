# Apache Avro™ 1.11.1 Documentation

## 介绍

Apache Avro 是一个数据序列化系统。

Avro 提供：

* 丰富的数据结构
* 一种紧凑（compact）、快速的二进制数据格式
* 容器文件，用于存储持久数据
* 远程过程调用（RPC）
* 与动态语言的简单集成。`读写数据文件` 或 `使用/实现 RPC协议`都不需要`代码生成（Code generation）`
  。代码生成是一个可选的优化，只值得为静态类型语言实现。

## 模式（Schemas）

Avro 依赖于模式。当读取 Avro 数据时，写入数据时使用的模式总是存在的。这允许在没有 `per-value 开销`
的情况下写入每个数据，使序列化既快速又小。这也有助于动态脚本语言的使用，因为数据及其模式是完全自描述的。

当 Avro 数据存储到一个文件中时，它的模式与它一起存储，因此文件可以稍后由任何程序处理。如果读取数据的程序期望使用不同的模式，这可以很容易地解决，因为两种模式都存在。

当在 RPC 中使用 Avro 时，客户端和服务器在连接握手中交换模式(可以对这一点进行优化，以便对于大多数的调用，实际上不传输模式)。
由于客户端和服务器都有对方的完整模式，所以相同命名字段之间的通信、缺失字段、额外字段等都可以很容易地解决。

## 与其他系统比较

Avro 提供类似于 [Thrift]()、[Protocol Buffers]() 等系统的功能。Avro 在以下几个基本方面与这些系统不同：

* `动态类型`：Avro不需要生成代码。数据总是伴随着一个模式，该模式允许完全处理该数据，而无需代码生成、静态数据类型等。这有助于构建通用的数据处理系统和语言。
* `未标记数据`：由于在读取数据时存在模式，因此数据编码时需要用的`类型信息`要少得多，这使得序列化大小更小。
* `无需手动分配字段ID`：当模式更改时，在处理数据时`旧模式`和`新模式`总是存在，因此可以使用`字段名`象征性地解决差异。

## [Getting Started (Java)](./getting-started-java.md)

## [Specification](https://avro.apache.org/docs/1.11.1/specification/)

## [MapReduce guide](https://avro.apache.org/docs/1.11.1/mapreduce-guide/)

## [IDL Language](https://avro.apache.org/docs/1.11.1/idl-language/)

## [SASL profile](https://avro.apache.org/docs/1.11.1/sasl-profile/)

