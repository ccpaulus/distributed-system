# # Language Guide (proto 3)

在 proto3 中，标量数字类型的 `repeated` 字段默认使用 `packed` 编码。您可以在[Protocol Buffer Encoding]()
中找到更多关于 `packed` 编码的信息。

支持生成的代码语言增加了：

* Kotlin
* Ruby
* Objective-C
* C#
* Dart

<span style="color:orange; ">proto2 消息类型 可以导入 proto3 消息中使用，反之亦然。但是，proto2 枚举不能在 proto3
语法中使用(如果导入的 proto2 消息使用它们那是可以的)。</span>

Proto3 支持 JSON 中的规范编码，使得在系统之间共享数据变得更加容易。




