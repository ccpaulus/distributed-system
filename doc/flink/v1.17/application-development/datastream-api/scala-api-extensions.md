All Flink Scala APIs are deprecated and will be removed in a future Flink version. You can still build your application
in Scala, but you should move to the Java version of either the DataStream and/or Table API.

See [FLIP-265 Deprecate and remove Scala API support]()

# Scala API 扩展

为了在 Scala 和 Java API 之间保持大致相同的使用体验，在批处理和流处理的标准 API 中省略了一些允许 Scala 高级表达的特性。

如果你想拥有完整的 Scala 体验，可以选择通过隐式转换增强 Scala API 的扩展。

要使用所有可用的扩展，你只需为 DataStream API 添加一个简单的引入

~~~
import org.apache.flink.streaming.api.scala.extensions._
~~~

或者，您可以引入单个扩展 a-là-carte 来使用您喜欢的扩展。

## Accept partial functions

通常，DataStream API 不接受匿名模式匹配函数来解构元组、case 类或集合，如下所示：

~~~
val data: DataStream[(Int, String, Double)] = // [...]
data.map {
  case (id, name, temperature) => // [...]
  // The previous line causes the following compilation error:
  // "The argument types of an anonymous function must be fully known. (SLS 8.5)"
}
~~~

这个扩展在 DataStream Scala API 中引入了新的方法，这些方法在扩展 API 中具有一对一的对应关系。这些委托方法支持匿名模式匹配函数。

### DataStream API

| Method      | Original                             | Example                                                                                                                                                                             |
|-------------|--------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| mapWith     | map (DataStream)                     | data.mapWith {<br/>  case (_, value) => value.toString<br/>}                                                                                                                        |
| flatMapWith | flatMap (DataStream)                 | data.flatMapWith {<br/>  case (_, name, visits) => visits.map(name -> _)<br/>}                                                                                                      |
| filterWith  | filter (DataStream)                  | data.filterWith {<br/>  case Train(_, isOnTime) => isOnTime<br/>}                                                                                                                   |
| keyingBy    | keyBy (DataStream)                   | data.keyingBy {<br/>  case (id, _, _) => id<br/>}                                                                                                                                   |
| mapWith     | map (ConnectedDataStream)            | data.mapWith(<br/>  map1 = case (_, value) => value.toString,<br/>  map2 = case (_, _, value, _) => value + 1<br/>)                                                                 |
| flatMapWith | flatMap (ConnectedDataStream)        | data.flatMapWith(<br/>  flatMap1 = case (_, json) => parse(json),<br/>  flatMap2 = case (_, _, json, _) => parse(json)<br/>)                                                        |
| keyingBy    | keyBy (ConnectedDataStream)          | data.keyingBy(<br/>  key1 = case (_, timestamp) => timestamp,<br/>  key2 = case (id, _, _) => id<br/>)                                                                              |
| reduceWith	 | reduce (KeyedStream, WindowedStream) | data.reduceWith {<br/>  case ((_, sum1), (_, sum2) => sum1 + sum2<br/>}                                                                                                             |
| projecting  | apply (JoinedStream)                 | data1.join(data2).<br/>  whereClause(case (pk, _) => pk).<br/>  isEqualTo(case (_, fk) => fk).<br/>  projecting {<br/>    case ((pk, tx), (products, fk)) => tx -> products<br/>  } |

有关每个方法语义的更多信息, 请参考 [DataStream API]() 文档。

要单独使用此扩展，你可以添加以下引入：

~~~
import org.apache.flink.api.scala.extensions.acceptPartialFunctions
~~~

用于 DataSet 扩展

~~~
import org.apache.flink.streaming.api.scala.extensions.acceptPartialFunctions
~~~

下面的代码片段展示了如何一起使用这些扩展方法 (以及 DataSet API) 的最小示例:

~~~
object Main {
  import org.apache.flink.streaming.api.scala.extensions._

  case class Point(x: Double, y: Double)

  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    val ds = env.fromElements(Point(1, 2), Point(3, 4), Point(5, 6))
    
    ds.filterWith {
      case Point(x, _) => x > 1
    }.reduceWith {
      case (Point(x1, y1), (Point(x2, y2))) => Point(x1 + y1, x2 + y2)
    }.mapWith {
      case Point(x, y) => (x, y)
    }.flatMapWith {
      case (x, y) => Seq("x" -> x, "y" -> y)
    }.keyingBy {
      case (id, value) => id
    }
  }
}
~~~