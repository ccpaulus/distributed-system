# 风格指南

本主题指导如何最好地构建原型定义。

本文档提供了 `.proto` 文件的风格指南。通过遵循这些约定，可以使得 protocol buffer 消息定义及其相应的类保持一致并易于阅读。

请注意，`protocol buffer 风格`会随着时间的推移而演变，因此您很可能会看到以不同的约定或风格编写的 `.proto` 文件。
在修改旧文件时请 ***尊重已有的样式***，***保持一致是关键*** 。但是，在创建新的 `.proto` 文件时，最好采用当前的最佳风格。

## 标准文件格式

* 保持`行长度`为 80 个字符。
* `缩进` 2 个空格。
* 建议对字符串使用`双引号`。

## 文件结构

文件应该命名为 `lower_snake_case.proto`。

所有文件应按以下方式排序：

* License header（如果适用）
* File overview
* Syntax
* Package
* Imports（排序）
* File options
* 其他

## Packages

Package 名称应该是小写的。包名应该是基于项目名的唯一名称，并且尽可能基于`包含 protocol buffer 类型定义`的文件路径。

## Message and Field Names

使用 PascalCase(带首字母大写) 作为 message 名称，例如 `SongServerRequest`。
字段名称(也包括 `oneof 字段` 和 `extension` 的名称)使用 lower_snake_case，例如 `song_name`。

~~~
message SongServerRequest {
  optional string song_name = 1;
}
~~~

对字段名使用这种命名规则，可以获得如下两个代码示例所示的访问函数：

### C++:

~~~
const string& song_name() { ... }
void set_song_name(const string& x) { ... }
~~~

### Java:

~~~
public String getSongName() { ... }
public Builder setSongName(String v) { ... }
~~~

如果字段名包含数字，则数字应出现在字母之后，而不是下划线之后。例如，使用`song_name1 `，而不是`song_name_1`。

## Repeated Fields

对 repeated 字段使用复数名称。

~~~
repeated string keys = 1;
  ...
  repeated MyMessage accounts = 17;
~~~

## Enums

枚举类型名称使用 PascalCase(带大写字母)，值名称使用 CAPITALS_WITH_UNDERSCORES(大写字母加下划线)：

~~~
enum FooBar {
  FOO_BAR_UNSPECIFIED = 0;
  FOO_BAR_FIRST_VALUE = 1;
  FOO_BAR_SECOND_VALUE = 2;
}
~~~

每个枚举值都应该以分号结束，而不是逗号。首选前缀枚举值，而不是把它们包围在封闭消息中。
零值枚举应该具有后缀 `UNSPECIFIED`，因为服务器或应用程序获得意外的枚举值将在 proto 实例中将该字段标记为未设置。
然后，字段访问函数将返回默认值（对于枚举字段，取第一个枚举值）。

## Services

如果您的 `.proto` 定义了 RPC 服务，那么您应该使用 PascalCase(带有大写字母) 作为 服务名 和 任何 RPC 方法名：

~~~
service FooService {
  rpc GetSomething(GetSomethingRequest) returns (GetSomethingResponse);
  rpc ListSomething(ListSomethingRequest) returns (ListSomethingResponse);
}
~~~

## Things to Avoid

* Required 字段 (仅适用于proto2)
* Groups (仅适用于proto2)

