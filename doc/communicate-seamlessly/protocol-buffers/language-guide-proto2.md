# Language Guide (proto 2)

## 定义 Message

~~~
syntax = "proto2"; //必填项

message SearchRequest {
  
  optional string query = 1;          // 1 是 field number  
  optional int32 page_number = 2;     // 标量类型（scalar types）
  optional int32 result_per_page = 3;
}

/* 一个 .proto 中可以有多个消息类型（例如message、enum、service）。
 * 为避免依赖关系膨胀。建议每个 .proto 文件包含尽可能少的消息类型。 */
message SearchResponse {
 ...
}
~~~

* field number，wire format使用，不可变；修改该值等同于删除了旧 field，并创建了新 number 的 field
* field number 不可重复，重用 field number 会使 wire-format 消息的解码变得模棱两可；使用一个定义对某字段进行编码，然后用不同的定义对同一个字段进行解码会出现问题：
    * 出现 parse/merge error（最好的情况）
    * 数据污染
    * PII/SPII 泄漏
* [19000,19999] 为保留值，不可用
* [1,15] 占用 一个字节；[16,2047] 占用 两个字节

***最大字段是 29 位，而不是更典型的 32 位，因为三个较低的位用于 wire-format。***

### 格式良好的消息

***格式良好*** 的 protobuf 消息，指代 ***序列化/反序列化的字节***，protoc 解析器验证给定的 proto 定义文件是否可解析。

在 `optional` 字段有多个值的情况下，protoc 解析器仅接收最后一个字段。
此时，字节可能不是 ***格式良好*** 的，但结果消息将只有一个，并且 ***格式良好***(但往返不相同)。

## 字段规则

Message 的字段可以是下列类型之一：

* `optional`：消息可以有 0 个或 1 个此字段(但不能超过 1 个)。
* `repeated`：该字段可以在消息中重复任意次数(包括 0 次)。重复值的顺序将被保留。
* `required`：***请勿使用***。已在proto3中删除。_必需字段的语义应该在应用层实现_。在使用该字段时，消息必须***正好***具有1
  个该字段。

由于历史原因，标量数字类型(例如int32、int64、enum)的重复字段没有被有效地编码。新代码应该使用特殊选项[packed = true]
来获得更有效的编码。例如：

~~~
repeated int32 samples = 4 [packed = true];
repeated ProtoEnum results = 5 [packed = true];
~~~

## 删除字段 & 保留字段

如果操作不当，删除字段可能会导致严重的问题。

***不要删除*** `required` 字段。这几乎是不可能安全地做到的。

当您不再需要非必需字段，并且所有引用都已从客户端代码中删除时，您可以从消息中删除字段定义。但是，您必须保留已删除的 field
number。如果您不保留 ，开发人员可能会在将来重用该编号。

您还应该保留字段名，以允许消息的 JSON 和 TextFormat 编码可以继续解析。

保留 field number 和 字段名：

~~~
message Foo {
  reserved 2, 15, 9 to 11;
  reserved "foo", "bar";
}
~~~

保留字段的取值范围是包含的(`9 to 11` 与 `9、10、11` 相同)。注意，不能在同一 `reserved` 语句中混合使用 字段名 和 字段号。

## .proto 生成了什么？

Protocol Buffer 编译器 根据`.proto`文件，为选定的语言生成代码，这些代码将用于处理文件中描述的消息类型，包括获取和设置字段值、将消息序列化到输出流以及从输入流解析消息。

例如： 对于 Java，编译器生成一个 `.java` 文件，其中包含每个消息类型的类，以及用于创建消息类实例的`Builder` 类。

## 标量值类型

标量消息字段可以具有以下类型之一，表中显示了 `.proto` 文件中指定的类型，以及自动生成的类中的相应类型：

| **.proto Type** | **Notes**                                  | **C++ Type** | **Java Type** | **Python Type[2]**                   | **Go Type** |
|-----------------|--------------------------------------------|--------------|---------------|--------------------------------------|-------------|
| double          |                                            | double       | double        | float                                | *float64    |
| float           |                                            | float        | float         | float                                | *float32    |
| int32           | 使用变长编码。编码负数时效率低下，如果字段可能具有负值，则使用 sint32 代替。 | int32        | int           | int                                  | *int32      |
| int64           | 使用变长编码。编码负数时效率低下，如果字段可能具有负值，则使用 sint64 代替。 | int64        | long          | int/long[3]                          | *int64      |
| uint32          | 使用变长编码。                                    | uint32       | int[1]        | int/long[3]                          | *uint32     |
| uint64          | 使用变长编码。                                    | uint64       | long[1]       | int/long[3]                          | *uint64     |
| sint32          | 使用变长编码。带符号整型值。它们比普通 int32 更有效地编码负数。        | int32        | int           | int                                  | *int32      |
| sint64          | 使用变长编码。带符号整型值。它们比普通 int64 更有效地编码负数。        | int64        | long          | int/long[3]                          | *int64      |
| fixed32         | 总是 4 个字节。如果值经常大于 2^28，则比 uint32 更有效。       | uint32       | int[1]        | int/long[3]                          | *uint32     |
| fixed64         | 总是 8 个字节。如果值通常大于 2^56，则比 uint64 更有效。       | uint64       | long[1]       | int/long[3]                          | *uint64     |
| sfixed32        | 总是 4 个字节。                                  | int32        | int           | int                                  | *int32      |
| sfixed64        | 总是 8 个字节                                   | int64        | long          | int/long[3]                          | *int64      |
| bool            |                                            | bool         | boolean       | bool                                 | *bool       |
| string          | 字符串必须始终包含 UTF-8 编码的文本。                     | string       | String        | unicode (Python 2) or str (Python 3) | *string     |
| bytes           | 可以包含任意字节序列。                                | string       | ByteString    | bytes                                | []byte      |

* [1] Java 中，无符号32位整数 和 64位整数 使用它们的有符号对应变体来表示，顶部位即是符号位。
* [2] 在所有情况下，为字段设置值将执行类型检查以确保它是有效的。
* [3] 64位整数 或 无符号32位整数 在解码时总是表示为 long，但如果在设置字段时给出 int，则可以表示为 int。
  在所有情况下，值必须适合设置时表示的类型。参见[2]。

## optional 字段和默认值

如上所述，消息描述中的元素可以标记为 `optional`。格式良好的消息可能包含也可能不包含可选元素。
在解析消息时，如果消息不包含可选元素，则访问已解析对象中的相应字段将返回该字段的默认值。
可以将默认值指定为消息描述的一部分。例如，假设您希望为 `SearchRequest` 的 `result_per_page` 提供一个默认值 10。

~~~
optional int32 result_per_page = 3 [default = 10];
~~~

如果没有为可选元素指定默认值，则使用类型指定的默认值：对于字符串，默认值为空字符串。对于字节，默认值是空字节串。对于 bool，默认值为
false。 对于数字类型，默认值为 0。对于枚举，默认值是枚举类型定义中列出的第一个值。这意味着在向枚举值列表的开头添加值时必须小心。
有关如何安全地更改定义的指南，请参阅[更新消息类型]()部分。

## Enumerations

~~~
enum Corpus {
  CORPUS_UNSPECIFIED = 0;
  CORPUS_UNIVERSAL = 1;
  CORPUS_WEB = 2;
  CORPUS_IMAGES = 3;
  CORPUS_LOCAL = 4;
  CORPUS_NEWS = 5;
  CORPUS_PRODUCTS = 6;
  CORPUS_VIDEO = 7;
}

message SearchRequest {
  optional string query = 1;
  optional int32 page_number = 2;
  optional int32 result_per_page = 3 [default = 10];
  optional Corpus corpus = 4 [default = CORPUS_UNIVERSAL];
}
~~~

可以通过将相同的值赋给不同的枚举常量来定义别名。为此，您需要将 `allow_alias` 选项设置为 `true`。
否则，当找到别名时，protocol buffer 编译器将生成一条警告消息。虽然所有别名值在反序列化期间都是有效的，但序列化时总是使用第一个值。

~~~
enum EnumAllowingAlias {
  option allow_alias = true;
  EAA_UNSPECIFIED = 0;  // 此处的 0 是枚举值，不是 field number
  EAA_UNKNOWN = 1;
  EAA_STARTED = 1;
  EAA_RUNNING = 2;
}
enum EnumNotAllowingAlias {
  ENAA_UNSPECIFIED = 0;
  ENAA_STARTED = 1;
  // ENAA_RUNNING = 1;  // Uncommenting this line will cause a warning message.
  ENAA_FINISHED = 2;
}
~~~

枚举消息定义中定义，也可以在消息定义之外定义；消息定义之外定义的枚举可以在 `.proto` 文件中的任何消息定义中重用。
还可以使用 `_MessageType_._EnumType_` 语法，将一个消息中声明的枚举类型用作另一个消息中字段的类型。

### 枚举保留值

如果移除一个 ***枚举项***（或将其注释），以后用户可以在对类型进行更新时重用该数值。这加载相同 `.proto` 的旧版本，会导致严重的问题（同
field number）。 为避免此问题，需要将 ***枚举项*** 指定为 `reserved`，此后再重用这些标示符，protocol buffer 编译器将报错。
可以使用 max 关键字指定保留的数值范围增加到最大可能值。

~~~
enum Foo {
  reserved 2, 15, 9 to 11, 40 to max;
  reserved "FOO", "BAR";
}
~~~

注意，不能在同一 `reserved` 语句中混合使用字段名和数值。

## 使用其他 Message 类型 作为字段类型

~~~
message SearchResponse {
  repeated Result result = 1;
}

message Result {
  optional string url = 1;
  optional string title = 2;
  repeated string snippets = 3;
}
~~~

引用的 message 不在同一个 `.proto` 文件时，需使用 import

~~~
import "myproject/other_protos.proto";
~~~

当引用的 `.proto` 文件移动到其他地方时，可以在原位置提供一个占位 `.proto` 文件，并使用 `import public` 将所有 imports
指向新文件的位置。
<span style="color:red; ">请注意，Java中不提供公共导入功能。</span>

~~~
// new.proto
// All definitions are moved here
~~~

~~~
// old.proto
// This is the proto that all clients are importing.
import public "new.proto";
import "other.proto";
~~~

~~~
// client.proto
import "old.proto";
// You use definitions from old.proto and new.proto, but not other.proto
~~~

一般来说，应该将 `--proto_path` 路径标志设置为项目的 root ，并对所有导入使用完全限定名。
该项不设定，则在调用编译器的目录中查找导入。

<span style="color:orange; ">proto3 消息类型 可以导入 proto2
消息中使用，反之亦然。但是，proto2 枚举不能在 proto3 语法中使用。</span>

## 嵌套类型

~~~
message SearchResponse {
  message Result {
    optional string url = 1;
    optional string title = 2;
    repeated string snippets = 3;
  }
  repeated Result result = 1;
}
~~~

通过 `_Parent_._Type_` 语法，在其他地方使用：

~~~
message SomeOtherMessage {
  optional SearchResponse.Result result = 1;
}
~~~

嵌套可以任意层级。

## 更新消息类型

`binary wire format` 的修改 与 `JSON 或 proto text format` 的修改是不同的。

请遵循以下规则：

* 不要更改任何现有字段号 。更改字段号相当于删除该字段并添加相同类型的新字段。如果需要对字段重新编号，请参见[删除字段]()的说明。
* 添加的任何新字段都应该是 `optional` 或 `repeated`。这意味着使用旧消息格式的代码序列化的任何消息都可以被新生成的代码解析，因为它们不会丢失任何必需的元素。
  您应该为这些元素设置合理的默认值，以便新代码可以正确地与旧代码生成的消息交互。类似地，由新代码创建的消息也可以由旧代码解析:
  旧二进制文件在解析时会忽略新字段。但是，unknown 字段不会被丢弃，并且如果稍后对消息进行序列化，则 unknown
  字段也会随之序列化，因此，如果将消息传递给新代码，新字段仍然可用。
* 只要在更新后的消息类型中不再使用老的字段号，就可以删除非必需字段。您可能想要重命名字段，也许添加前缀 `OBSOLETE_`
  ，或者保留字段号，以便将来使用 .proto 的用户不会意外地重用该编号。
* 只要类型和字段号保持不变，非必需字段可以转换为 extension 类型，反之亦然。
* `Int32`, `uint32`, `int64`, `uint64` 和 `bool` 都是兼容的，这意味着您可以将这些类型中的一个字段更改为另一个，而不会破坏向前或向后兼容性。
  如果从 wire 中解析的数字不适合相应的类型，则会得到与在 C++ 中将该数字强制转换为该类型相同的效果(例如，如果将 64
  位数字读取为 `int32`，则会将其截断为 32 位)。
* `sint32` 和 `sint64` 相互兼容，但与其他整数类型不兼容。
* 只要字节是有效的 UTF-8, `string` 和 `bytes` 是兼容的。
* 如果字节包含消息的编码版本，则嵌入式消息与 `bytes` 兼容。
* `fixed32` 与 `sfixed32` 兼容，`fixed64` 与 `sfixed64` 兼容。
* 对于 `string`, `bytes` 和 `message` 类型的字段，`optional` 与 `repeated` 兼容。
  给定一个重复字段的序列化数据作为输入，如果该字段是基本类型字段，希望该字段是 `optional`
  的客户端将接受最后一个输入值，如果是 `message` 息类型字段，则合并所有输入元素。
  请注意，这对于数值类型(包括 bool 和 enum )通常***不安全***。数值类型的重复字段可以以`packed 格式`
  序列化，当期望使用 `optional` 字段时，将无法正确解析该格式。
* 更改默认值通常是可以的，记住默认值永远不会通过网络发送。因此，如果一个程序接收到一条消息，消息的某个字段没有值，该程序将使用在该程序版本的协议中定义的默认值，而不是发送方代码中的。
* `enum` 在 wire 格式方面与 `int32`, `uint32`, `int64` 和 `uint64` 兼容(请注意，如果不适合，值将被截断)，
  但请注意，在对消息进行反序列化时，客户端代码可能会以不同的方式对待它们。值得注意的是，当消息被反序列化时，无法识别的 `enum`
  值将被丢弃，这使得字段 `has..` 访问函数返回 false，其 getter 返回 `enum` 定义中列出的第一个值，如果指定了默认值，则返回默认值。
  在重复枚举字段的情况下，任何无法识别的值都将从列表中删除。但是，整数字段将始终保持其值。因此，在将整数升级为 `enum`
  时需要非常小心，以免在 wire 上接收超出边界的枚举值。
* 在当前的 Java 和 C++ 实现中，当无法识别的 `enum` 值被删除时，它们与其他未知字段一起存储。请注意，如果将此数据序列化，然后由识别这些值的客户机解析，则可能导致奇怪的行为。
  在可选字段的情况下，即使在对原始消息进行反序列化之后写入新值，旧值仍然会被识别它的客户端读取。在重复字段的情况下，旧值将出现在任何已识别的和新添加的值之后，这意味着将不保留顺序。
* 将单个 `optional` 字段或 `extension` 更改为新的 `oneof`的成员是二进制兼容的，但是对于某些语言(特别是 Go )，生成代码的
  API 将以不兼容的方式更改。由于这个原因，Google 没有在其公共 API 中进行这样的更改，正如在 [AIP-180]() 中记录的那样。
  关于源代码兼容性的警告是一样的，如果您确定没有代码一次设置多个字段，那么将多个字段移动到一个新的 `oneof`
  中可能是安全的。将字段移动到现有的 `oneof` 中是不安全的。同样，将单个字段 `oneof` 更改为 `optional` 字段或 `extension`
  也是安全的。
* 在 `map<K, V>` 和相应的 `repeated` 消息字段之间更改字段是二进制兼容的(参见下面的 [Maps]()，了解消息布局和其他限制)。
  然而，更改的安全性依赖于应用程序：当反序列化和重新序列化消息时，使用 `repeated` 字段定义的客户端将产生语义相同的结果；
  但是，使用 `map` 字段定义的客户端可以重新排序条目并删除具有重复键的条目。

## Extensions

extension 是在其容器消息之外定义的字段；通常在一个`.proto`文件中，与容器消息的`.proto`文件分开。

使用 extension 有两个主要原因：

* 减少容器消息的`.proto`文件的 ***导入/依赖***。这可以缩短构建时间，打破循环依赖，或者促进松耦合。
* 允许系统以最小的 ***依赖*** 和 ***协调*** 将数据附加到容器消息。关于此项，由于 ***有限的字段号空间*** 和
  ***重用字段号的后果*** ， extension 不是一个太好的解决方案。如果您的用例对大量 extension
  的协调要求非常低，请考虑使用 [Any 消息类型]()。

***kittens/video_ext.proto***

~~~
import "kittens/video.proto";
import "media/user_content.proto";   // container message’s file

package kittens;

// This extension allows kitten videos in a media.UserContent message.
extend media.UserContent {
  // Video is a message imported from kittens/video.proto
  repeated Video kitten_videos = 126;
}
~~~

***media/user_content.proto***

~~~
package media;

// A container message to hold stuff that a user has created.
message UserContent {
  // 为 extensions 保留字段编号[100至199]，不能用于标准字段
  // 及具有非常大的字段号，则可以使用 max 关键字（ extensions 1000 to max ）
  // 注意此字段号同样不能重用
  extensions 100 to 199;
}
~~~

<span style="color:orange; ">`media/user_content.proto` 不需要导入 `kittens/video_ext.proto`
<br/><br/>将标准字段移出其容器作为 extension 或 将 extension 移到其容器消息中作为标准字段都是安全的。
<br/><br/>由于 extension 是在容器消息之外定义的，因此没有生成专门的访问器来获取和设置特定的扩展字段。
对于当前例子，protobuf 编译器不会生成`AddKittenVideos()`或`GetKittenVideos()`访问器。
相反，可以通过参数化函数访问扩展，例如：`HasExtension()`, `ClearExtension()`, `GetExtension()`, `MutableExtension()`
和 `AddExtension()`。
<br/><br/>extension 可以是除 `oneof` 和 `map` 之外的任何字段类型。
<br/><br/>extension `不建议嵌套`在其他类型中，且外部类型 和 extension 类型之间不存在任何关系。最好使用`标准(文件级)语法`
，因为嵌套语法经常被不熟悉扩展的用户误认为是子类化。
</span>

## Any

`Any` 消息类型允许您使用消息作为嵌入类型，而不需要它们的 .proto 定义。
`Any` 包含任意序列化的字节消息，以及作为该消息类型的`全局唯一标识符`并解析为该消息类型的 URL。
使用 Any 类型，需要 import `google/protobuf/any.proto`。

~~~
import "google/protobuf/any.proto";

message ErrorStatus {
  string message = 1;
  repeated google.protobuf.Any details = 2;
}
~~~

给定消息类型的默认类型URL为 `type.googleapis.com/_packagename_._messagename_`。

## Oneof

如果您的消息具有许多可选字段，并且同时最多将设置一个字段，则可以通过使用 `oneof` 特性强制执行此行为并节省内存。

~~~
message SampleMessage {
  oneof test_oneof {
     string name = 4;
     SubMessage sub_message = 9;
  }
}
~~~

将 `oneof` 字段添加到 `oneof` 定义中。可以添加任何类型的字段，但不能使用 `required`, `optional` 或 `repeated` 关键字。
如果需要向 `oneof` 中一个添加重复字段，可以使用包含重复字段的消息。

在生成的代码中，`oneof` 字段具有与常规可选方法相同的 getter 和 setter 。
您还可以获得一个特殊的方法，用于检查 `oneof` 中的哪个值(如果有的话)已设置。您可以在相关的[API参考]()
中找到有关所选语言的 `oneof` API 的更多信息。

特性：

* 设置 oneof 字段将自动清除 oneof 字段的所有其他成员。因此，如果您设置了几个 oneof 字段，那么只有您设置的 ***最后一个***
  字段仍然具有值。
  ~~~
  SampleMessage message;
  SampleMessage message;
  message.set_name("name");
  CHECK(message.has_name());
  message.mutable_sub_message();   // Will clear name field.
  CHECK(!message.has_name());
  ~~~
* 如果解析器在网络上遇到同一个 oneof 的多个成员，则只在解析的消息中使用最后一个成员。
* oneof 不支持 extensions 。
* oneof 不能是 `repeated` 。
* Reflection APIs 适用于 oneof 字段。
* 如果您将 oneof 字段设置为默认值(例如将 `int32 oneof` 字段设置为 0)，则该 oneof 字段的 `case` 将被设置，并且该值将在 wire
  上序列化。
* 如果您正在使用 C++，请确保您的代码不会导致内存崩溃。下面的示例代码将崩溃，因为已经通过调用`set_name()`
  方法删除了`sub_message` 。
  ~~~
  SampleMessage message;
  SubMessage* sub_message = message.mutable_sub_message();
  message.set_name("name");      // Will delete sub_message
  sub_message->set_...            // Crashes here
  ~~~
* 同样，在 C++ 中，如果使用 `Swap()` 两个消息，每个消息将以另一个 oneof case 结束:在下例中，`msg1`
  将有一个 `sub_message` ，`msg2` 将有一个 `name`。
  ~~~
  SampleMessage msg1;
  msg1.set_name("name");
  SampleMessage msg2;
  msg2.mutable_sub_message();
  msg1.swap(&msg2);
  CHECK(msg1.has_sub_message());
  CHECK(msg2.has_name());
  ~~~

### 向后兼容性问题

已下情况会出现向后兼容问题：

* 将可选字段移进或移出 oneof
* 删除 oneof 字段又将其添加回来
* 拆分或合并 oneof

## Maps

如果您希望创建 map 作为数据定义的一部分，protocol buffers 提供了一种方便的快捷语法：

~~~
map<key_type, value_type> map_field = N;
~~~

`key_type` 可以是任何整数或字符串类型（即任何标量类型，除了浮点类型和字节）。
注意 `enum` 不能是 `key_type`。`value_type` 可以是任何类型，除了另一个 map。

~~~
map<string, Project> projects = 3;
~~~

特性：

* map 不支持 extension。
* map 不能是 `repeated`, `optional` 或 `required`。
* map 值的 wire 格式排序 和 map 迭代排序是未定义的，因此不能依赖于 map 项的特定顺序。
* 在为 `.proto` 生成文本格式时，map 按键排序。数字键按数字排序。
* 在从 wire 进行解析 或 合并时，如果存在重复的 map 键，则使用最后的键。从文本格式解析 map 时，如果存在重复键，解析可能会失败。

### 向后兼容性

map 语法在 wire 上等同于下面的语法，因此不支持 map 的 protocol buffer 实现仍然可以处理您的数据：

~~~
message MapFieldEntry {
  optional key_type key = 1;
  optional value_type value = 2;
}

repeated MapFieldEntry map_field = N;
~~~

任何支持 map 的 protocol buffer 实现都必须 ***产生*** 并 ***接受*** 可以被上述定义接受的数据。

## Packages

在 `.proto` 中 添加 `package` 声明

~~~
package foo.bar;
message Open { ... }
~~~

使用 `package` 声明

~~~
message Foo {
  ...
  optional foo.bar.Open open = 1;
  ...
}
~~~

## 定义 Services

如果您想在 RPC(远程过程调用)系统 中使用您的消息类型，您可以在 `.proto` 文件中定义RPC服务接口，protocol buffer
编译器将用您选择的语言生成 service 接口代码和存根。
因此，例如，如果您希望定义一个RPC服务，该服务使用一个接受 `SearchRequest` 并返回 `SearchResponse` 的方法：

~~~
service SearchService {
  rpc Search(SearchRequest) returns (SearchResponse);
}
~~~

## Options

`.proto` 文件中的单个声明可以用许多 option 进行注释。option 不会改变声明的整体含义，但可能会影响在特定上下文中处理声明的方式。

### 文件级 option，写在顶层作用域中

~~~
// 生成的 Java 类的包
option java_package = "com.example.foo";

// 要生成的 Java 类的类名(以及文件名)
// 不设置，则类名将通过将.proto文件名转换为驼峰格式来构造(例如 foo_bar.proto 变成 FooBar.java)。
option java_outer_classname = "Ponycopter";

// messages, services, and enumerations 生成的代码是否拆分独立 Java 文件
option java_multiple_files = true;

// 影响 C++ 和 Java代码生成器
// 可以设置为 SPEED，CODE_SIZE，或 LITE_RUNTIME
// SPEED(默认)，生成的代码是高度优化的
// CODE_SIZE，生成最少的类，但操作将变慢
// LITE_RUNTIME， 生成仅依赖于 lite 运行时库(libprotobuf-lite)的类。比完整的库小得多(大约小一个数量级)，但省略了某些特性，如描述符和反射。这对于在手机等受限平台上运行的应用程序尤其有用。
option optimize_for = CODE_SIZE;

// This file relies on plugins to generate service code.
option cc_generic_services = false;
option java_generic_services = false;
option py_generic_services = false;

// 如果在基本数字类型的重复字段上设置为true，则使用更紧凑的编码。2.3.0版本之前，更改此设置不安全。
repeated int32 samples = 4 [packed = true];

// 如果设置为true，表示该字段已弃用，不应被新代码使用。在大多数语言中，这没有实际效果。在Java中，这变成了@Deprecated注释。
optional int32 old_field = 6 [deprecated=true];
~~~

### 消息级 option，写在消息定义中

~~~
message Foo {
  // 如果设置为true，则消息使用一种不同的二进制格式，旨在与Google内部使用的旧格式MessageSet兼容。谷歌以外的用户可能永远不需要使用这个选项。
  option message_set_wire_format = true;
  extensions 4 to max;
}
~~~

### 字段级 option，写在字段定义中

### Enum Value Options

### Custom Options

### Option Retention

### Option Targets

## 生成 Classes

生成`.proto`文件中定义的消息类型的 Java、 Python 或 C++ 代码，需要在`.proto`上运行 protocol buffer
编译器 `protoc`。 首先安装编译器。

~~~
protoc --proto_path=IMPORT_PATH --cpp_out=DST_DIR --java_out=DST_DIR --python_out=DST_DIR path/to/file.proto
~~~

