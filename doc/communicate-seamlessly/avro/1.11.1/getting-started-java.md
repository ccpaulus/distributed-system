# Getting Started (Java)

这是一个使用 Java 开始使用 Apache Avro 的简短指南。本指南仅涵盖使用 Avro 进行数据序列化; 详细介绍参考： Patrick Hunt
的 [Avro RPC 快速入门]()。

## 下载

Avro 的 C, C++, C#, Java, PHP, Python 和 Ruby 实现 可以从 [Apache Avro下载]() 页面下载。
本指南使用 Avro 1.11.1。对于本指南中的示例，下载 avro-1.11.1.jar 和 avro-tools-1.11.1.jar 。

或者，如果您正在使用Maven，请向POM添加以下依赖项：

~~~
<dependency>
  <groupId>org.apache.avro</groupId>
  <artifactId>avro</artifactId>
  <version>1.11.1</version>
</dependency>
~~~

以及 Avro Maven 插件(用于执行代码生成)：

~~~
<plugin>
  <groupId>org.apache.avro</groupId>
  <artifactId>avro-maven-plugin</artifactId>
  <version>1.11.1</version>
  <executions>
    <execution>
      <phase>generate-sources</phase>
      <goals>
        <goal>schema</goal>
      </goals>
      <configuration>
        <sourceDirectory>${project.basedir}/src/main/avro/</sourceDirectory>
        <outputDirectory>${project.basedir}/src/main/java/</outputDirectory>
      </configuration>
    </execution>
  </executions>
</plugin>
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-compiler-plugin</artifactId>
  <configuration>
    <source>1.8</source>
    <target>1.8</target>
  </configuration>
</plugin>
~~~

## 定义模式

Avro 模式是使用 JSON 定义的。模式由 `基本类型(null、boolean、int、long、float、double、bytes 和 string)`
和 `复杂类型(record、enum、array、map、union 和 fixed)`组成。您可以从规范中了解更多关于 Avro 模式 和 类型 的信息，现在让我们从一个简单的模式示例
`user.avsc` 开始：

~~~
{"namespace": "example.avro",
 "type": "record",
 "name": "User",
 "fields": [
     {"name": "name", "type": "string"},
     {"name": "favorite_number",  "type": ["int", "null"]},
     {"name": "favorite_color", "type": ["string", "null"]}
 ]
}
~~~

上面模式定义了一个表示 `用户` 的记录。(请注意，一个模式文件只能包含一个模式定义)
记录定义至少必须包括它的 `类型(type: record)`、`名称(name: User)` 和 `字段`（在本例中是 name、favorite_number 和
favorite_color）。 我们还定义了一个`命名空间("namespace": "example.avro")`，它与 name
属性一起定义模式的`全名(在本例中为 example.avro.User)`。

`fields`是通过一个`对象数组`定义的，每个对象定义了一个 name 和 type (其他属性是`可选的`，请参阅[记录规范]()了解更多细节)。
字段的 type 属性 是另一个模式对象，它可以是`基本类型`，也可以是`复杂类型`。
例如，User 模式的 name 字段是`基本类型 string`，而 favorite_number 和 favorite_color 字段都是 `union`，由JSON数组表示。
`union`是一种`复杂类型`，可以是数组中列出的任何类型；例如，favorite_number 可以是 int 或 null，本质上使它成为一个`可选字段`。

## 使用代码生成进行 序列化 和 反序列化

### 编译 schema

`代码生成`允许我们基于前面定义的模式自动创建类。一旦定义了相关类，就`不需要`在程序中直接使用模式。我们使用 avro-tools jar
生成如下代码：

~~~
java -jar /path/to/avro-tools-1.11.1.jar compile schema <schema file> <destination>
~~~

这将根据提供的目标文件夹中的模式的 namespace 在包中生成适当的源文件。例如，在包示例中生成 User 类。从上面定义的模式Avro中运行：

~~~
java -jar /path/to/avro-tools-1.11.1.jar compile schema user.avsc .
~~~

注意，如果你使用 Avro Maven 插件，不需要手动调用模式编译器；该插件自动对配置的 source 目录中存在的任何`.avsc`文件执行代码生成。

### 创建 Users

现在我们已经完成了代码生成，让我们创建一些 User，将它们序列化到磁盘上的一个数据文件，然后回读该文件并反序列化 User 对象。

首先，让我们创建一些 User 并设置它们的 fields。

~~~
User user1 = new User();
user1.setName("Alyssa");
user1.setFavoriteNumber(256);
// Leave favorite color null

// Alternate constructor
User user2 = new User("Ben", 7, "red");

// Construct via builder
User user3 = User.newBuilder()
             .setName("Charlie")
             .setFavoriteColor("blue")
             .setFavoriteNumber(null)
             .build();
~~~

如本例所示，Avro 对象既可以通过直接调用 constructor 创建，也可以通过使用 builder 创建。
与 constructor 不同，builder 将自动设置模式中指定的任何默认值。 此外，builder 在数据设置时验证数据，而直接构造的对象在被序列化之前不会导致错误。
但是，直接使用 constructor 通常提供更好的性能，因为 builder 在编写数据结构之前需要创建数据结构的副本。

注意，我们没有设置 user1 的 favorite_color 。由于该记录的类型为`[string, null]`，我们可以将其设置为 `字符串` 或
将其保留为`null`，它本质上是可选的。类似地，我们将 user3 的 favorite_number 设置为 null (使用 builder 需要设置所有字段，即使它们为
null)。

### 序列化

现在让我们将用户序列化到磁盘。

~~~
// Serialize user1, user2 and user3 to disk
DatumWriter<User> userDatumWriter = new SpecificDatumWriter<User>(User.class);
DataFileWriter<User> dataFileWriter = new DataFileWriter<User>(userDatumWriter);
dataFileWriter.create(user1.getSchema(), new File("users.avro"));
dataFileWriter.append(user1);
dataFileWriter.append(user2);
dataFileWriter.append(user3);
dataFileWriter.close();
~~~

我们创建了一个 DatumWriter，它将 Java 对象转换为内存中的序列化格式。SpecificDatumWriter 类与生成的类一起使用，并从指定的生成类型中提取模式。

接下来，我们创建一个 DataFileWriter，它将序列化的记录以及模式写入 dataFileWriter.create 中指定的文件。我们通过调用
dataFileWriter.append 将用户写入文件。当我们完成写入时，关闭数据文件。

### 反序列化

最后，让我们对刚刚创建的数据文件进行反序列化。

~~~
// Deserialize Users from disk
DatumReader<User> userDatumReader = new SpecificDatumReader<User>(User.class);
DataFileReader<User> dataFileReader = new DataFileReader<User>(file, userDatumReader);
User user = null;
while (dataFileReader.hasNext()) {
// Reuse user object by passing it to next(). This saves us from
// allocating and garbage collecting many objects for files with
// many items.
user = dataFileReader.next(user);
System.out.println(user);
}
~~~

这个代码片段将输出：

~~~
{"name": "Alyssa", "favorite_number": 256, "favorite_color": null}
{"name": "Ben", "favorite_number": 7, "favorite_color": "red"}
{"name": "Charlie", "favorite_number": null, "favorite_color": "blue"}
~~~

反序列化与序列化非常相似。我们创建了一个 SpecificDatumReader，类似于我们在序列化中使用的
SpecificDatumWriter，它将内存中序列化的项转换为我们生成的类的实例（在本例中是 User）。
我们将 DatumReader 和前面创建的 File 传递给 DataFileReader (类似于 DataFileReader)，它既读取 writer 使用的模式，也读取磁盘上文件中的数据。
读取数据时使用 `文件中包含的 writer 模式` 和 `reader 提供的模式`，在本例中是 `User 类`。
writer 的模式需要知道字段写入的顺序，而 reader 的模式需要知道 期望哪些字段 以及 如何填写添加字段的默认值。
如果两个模式之间存在差异，则根据模式解析规范进行解析。

接下来，我们使用 DataFileReader 遍历序列化的 Users，并将反序列化的对象打印到 stdout。 注意我们是如何执行迭代的：
我们创建了一个 User 对象来存储当前反序列化的用户，并将这个记录对象传递给 dataFileReader.next 的每次调用。
这是一种性能优化，它允许 DataFileReader 重用相同的 User 对象，而不是为每次迭代分配一个新的
User，如果我们反序列化一个大数据文件，那对象分配和垃圾收集方面可能会非常昂贵。
虽然这种技术是遍历数据文件的标准方法，但如果不考虑性能问题，也可以使用`for (User User: dataFileReader)`。

### 编译并运行示例代码

该示例代码作为 Maven 项目包含在 Avro docs 的 examples/java-example 目录中。
从该目录中，执行以下命令来构建并运行示例：

~~~
$ mvn compile # includes code generation via Avro Maven plugin
$ mvn -q exec:java -Dexec.mainClass=example.SpecificMain
~~~

### Beta特性:生成更快的代码

在 1.9.0 版本中，我们引入了一种生成代码的新方法，可以将对象的解码速度提高 10% 以上，编码速度提高 30% 以上(
未来的性能增强正在进行中)。
为了确保将此更改顺利引入生产系统，该特性由一个特性标志控制，即系统属性 org.apache.avro.specific.use_custom_coders。
在第一个版本中，该特性默认关闭。要打开它，请在运行时将系统标志设置为true。例如，在上面的示例中，您可以像下面这样启用父编码器

~~~
$ mvn -q exec:java -Dexec.mainClass=example.SpecificMain -Dorg.apache.avro.specific.use_custom_coders=true
~~~

注意，您不必重新编译 Avro 模式来访问此特性。该特性被编译并内置于代码中，您可以在运行时使用特性标志打开或关闭它。
因此，您可以在测试期间打开它，然后在生产中关闭它。您也可以在生产环境中打开它，并在出现故障时快速关闭它。

我们鼓励 Avro 社区尽早运用这个新功能，以帮助建立信心。(对于那些为云计算资源一次性付费的人来说，这可以节省大量成本。)
随着信心的建立，我们将默认开启该特性，并最终消除该特性标志(以及旧代码)。

## 不生成代码的 序列化 和 反序列化

Avro 中的数据总是与相应的模式一起存储，这意味着无论我们是否提前知道模式，我们都可以读取序列化的项。这允许我们在不生成代码的情况下执行序列化和反序列化。

让我们回顾一下与前一节相同的示例，但不使用代码生成:我们将创建一些用户，将它们序列化到磁盘上的数据文件，然后回读该文件并反序列化用户对象。

### 创建 users

首先，使用 Parser 读取模式定义并创建 schema 对象。

~~~
Schema schema = new Schema.Parser().parse(new File("user.avsc"));
~~~

使用这个模式，让我们创建一些用户。

~~~
GenericRecord user1 = new GenericData.Record(schema);
user1.put("name", "Alyssa");
user1.put("favorite_number", 256);
// Leave favorite color null

GenericRecord user2 = new GenericData.Record(schema);
user2.put("name", "Ben");
user2.put("favorite_number", 7);
user2.put("favorite_color", "red");
~~~

因为我们不使用代码生成，所以我们使用 GenericRecords 来表示用户。GenericRecord 使用模式来验证字段（仅我们指定了有效的）。
如果我们尝试设置一个不存在的字段（例如，user1.put(“favorite_animal”, “cat”)），我们将在运行程序时得到 AvroRuntimeException。

注意，我们没有设置 user1 的 favorite color。由于该记录的类型为[string, null]，我们可以将其设置为字符串或将其保留为null；它本质上是可选的。

### 序列化

现在我们已经创建了用户对象，对它们进行 `序列化` 和 `反序列化` 几乎与上面使用代码生成的示例相同。
主要的区别是我们使用通用的而不是特定的 readers 和 writers。

首先，我们将把用户序列化到磁盘上的一个数据文件。

~~~
// Serialize user1 and user2 to disk
File file = new File("users.avro");
DatumWriter<GenericRecord> datumWriter = new GenericDatumWriter<GenericRecord>(schema);
DataFileWriter<GenericRecord> dataFileWriter = new DataFileWriter<GenericRecord>(datumWriter);
dataFileWriter.create(schema, file);
dataFileWriter.append(user1);
dataFileWriter.append(user2);
dataFileWriter.close();
~~~

我们创建了一个 DatumWriter，它将 Java 对象转换为内存中的序列化格式。因为我们没有使用代码生成，所以我们创建了一个
GenericDatumWriter。它要求模式既要确定如何编写 GenericRecords，又要验证是否存在所有非空字段。

与代码生成示例一样，我们还创建了一个 DataFileWriter，它将序列化的记录以及模式写入 dataFileWriter.create 中指定的文件。
我们通过调用 dataFileWriter.append 将用户写入文件。当我们完成写入时，我们关闭数据文件。

### 反序列化

最后，我们将对刚刚创建的数据文件进行反序列化。

~~~
// Deserialize users from disk
DatumReader<GenericRecord> datumReader = new GenericDatumReader<GenericRecord>(schema);
DataFileReader<GenericRecord> dataFileReader = new DataFileReader<GenericRecord>(file, datumReader);
GenericRecord user = null;
while (dataFileReader.hasNext()) {
// Reuse user object by passing it to next(). This saves us from
// allocating and garbage collecting many objects for files with
// many items.
user = dataFileReader.next(user);
System.out.println(user);
~~~

这个代码片段将输出：

~~~
{"name": "Alyssa", "favorite_number": 256, "favorite_color": null}
{"name": "Ben", "favorite_number": 7, "favorite_color": "red"}
~~~

反序列化与序列化非常相似。我们创建了一个 GenericDatumReader，类似于我们在序列化中使用的 GenericDatumWriter，它将内存中的序列化项转换为
GenericRecords。
我们将 DatumReader 和前面创建的 File 传递给 DataFileReader (类似于DataFileReader)，它既读取 writer 使用的模式，也读取磁盘上文件中的数据。
数据通过使用 writer 的模式（包含在文件中）和 提供给 GenericDatumReader 的 reader 模式来读取。writer 的模式需要知道字段写入的顺序，
而 reader 的模式需要知道 期望哪些字段 以及 如何填写添加字段的默认值。
如果两个模式之间存在差异，则根据模式解析规范进行解析。

接下来，使用 DataFileReader 遍历序列化的用户，并将反序列化的对象打印到标准输出。注意我们是如何执行迭代的：
我们创建了一个 GenericRecord 对象来存储当前反序列化的用户，并将这个记录对象传递给 dataFileReader.next 的每次调用。
这是一种性能优化，允许 DataFileReader 重用相同的记录对象，而不是为每次迭代分配一个新的 GenericRecord
，如果我们反序列化一个大数据文件，那对象分配和垃圾收集方面可能会非常昂贵。
虽然这种技术是遍历数据文件的标准方法，但如果不考虑性能问题，也可以将其用于`(GenericRecord User: dataFileReader)`。

### 编译并运行示例代码

~~~
$ mvn compile
$ mvn -q exec:java -Dexec.mainClass=example.GenericMain
~~~

