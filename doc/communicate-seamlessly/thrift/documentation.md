# Apache Thrift

Apache Thrift 软件框架，用于`可扩展`的`跨语言`服务开发，将软件栈与代码生成引擎相结合，
构建在 C++, Java, Python, PHP, Ruby, Erlang, Perl, Haskell, C#, Cocoa, JavaScript, Node.js, Smalltalk, OCaml 和 Delphi
等语言之间高效无缝工作的服务。

## 入门

* 下载 Apache Thrift
  <br/>首先，[下载]()一份 Thrift 的拷贝。
* 构建并安装 Apache Thrift 编译器
  <br/>然后，您需要[构建]() Apache Thrift 编译器并安装它。关于这一步，请参阅[安装 Thrift]()指南。
* 编写 .thrift 文件
  <br/>在安装了 Thrift 编译器之后，您需要创建一个 Thrift 文件。该文件是由 [thrift types]() 和 Services
  组成的 [接口定义]()。您在此文件中定义的 services 由服务端实现，并由任何客户端调用。
  Thrift 编译器 用于将你的 Thrift 文件生成`源代码`，供不同的客户端库和你编写的服务端使用。要从 Thrift 文件生成源代码，请运行：
  ~~~
  thrift --gen <language> <Thrift filename>
  ~~~
  样例文件
  tutorial.thrift，用于所有客户端和服务端的教程都可以在[这里](https://github.com/apache/thrift/tree/master/tutorial)找到

要了解更多关于Apache Thrift的信息，请阅读[白皮书](https://thrift.apache.org/static/files/thrift-20070401.pdf)

## 例子

Apache Thrift 允许您在一个简单的定义文件中定义`数据类型`和`服务接口`
。将该文件作为输入，编译器生成代码，用于轻松构建 `跨编程语言无缝通信的` RPC 客户端和服务端。不必编写大量的样板代码来序列化和传输对象以及调用远程方法，您可以直接进入正题。

下面的例子是一个为 web 前端 存储用户对象的简单服务。

### Thrift Definition File

~~~
/**
 * Ahh, now onto the cool part, defining a service. Services just need a name
 * and can optionally inherit from another service using the extends keyword.
 */
service Calculator extends shared.SharedService {

  /**
   * A method definition looks like C code. It has a return type, arguments,
   * and optionally a list of exceptions that it may throw. Note that argument
   * lists and exception lists are specified using the exact same syntax as
   * field lists in struct or exception definitions.
   */

   void ping(),

   i32 add(1:i32 num1, 2:i32 num2),

   i32 calculate(1:i32 logid, 2:Work w) throws (1:InvalidOperation ouch),

   /**
    * This method has a oneway modifier. That means the client only makes
    * a request and does not listen for any response at all. Oneway methods
    * must be void.
    */
   oneway void zip()

}
~~~

此代码片段是由 Apache Thrift 的源代码树文档生成：[tutorial/tutorial.thrift]()

### Python Client

~~~
def main():
    # Make socket
    transport = TSocket.TSocket('localhost', 9090)

    # Buffering is critical. Raw sockets are very slow
    transport = TTransport.TBufferedTransport(transport)

    # Wrap in a protocol
    protocol = TBinaryProtocol.TBinaryProtocol(transport)

    # Create a client to use the protocol encoder
    client = Calculator.Client(protocol)

    # Connect!
    transport.open()

    client.ping()
    print('ping()')

    sum_ = client.add(1, 1)
~~~

此代码片段是由 Apache Thrift 的源代码树文档生成：[tutorial/py/PythonClient.py]()

### Java Server

~~~
try {
  TServerTransport serverTransport = new TServerSocket(9090);
  TServer server = new TSimpleServer(new Args(serverTransport).processor(processor));

  // Use this for a multithreaded server
  // TServer server = new TThreadPoolServer(new TThreadPoolServer.Args(serverTransport).processor(processor));

  System.out.println("Starting the simple server...");
  server.serve();
} catch (Exception e) {
  e.printStackTrace();
}
~~~

此代码片段是由 Apache Thrift 的源代码树文档生成：[tutorial/java/src/JavaServer.java]()

~~~
public class CalculatorHandler implements Calculator.Iface {

  private HashMap<Integer,SharedStruct> log;

  public CalculatorHandler() {
    log = new HashMap<Integer, SharedStruct>();
  }

  public void ping() {
    System.out.println("ping()");
  }

  public int add(int n1, int n2) {
    System.out.println("add(" + n1 + "," + n2 + ")");
    return n1 + n2;
  }

  public int calculate(int logid, Work work) throws InvalidOperation {
    System.out.println("calculate(" + logid + ", {" + work.op + "," + work.num1 + "," + work.num2 + "})");
    int val = 0;
    switch (work.op) {
    case ADD:
      val = work.num1 + work.num2;
      break;
    case SUBTRACT:
      val = work.num1 - work.num2;
      break;
    case MULTIPLY:
      val = work.num1 * work.num2;
      break;
    case DIVIDE:
      if (work.num2 == 0) {
        InvalidOperation io = new InvalidOperation();
        io.whatOp = work.op.getValue();
        io.why = "Cannot divide by 0";
        throw io;
      }
      val = work.num1 / work.num2;
      break;
    default:
      InvalidOperation io = new InvalidOperation();
      io.whatOp = work.op.getValue();
      io.why = "Unknown operation";
      throw io;
    }

    SharedStruct entry = new SharedStruct();
    entry.key = logid;
    entry.value = Integer.toString(val);
    log.put(logid, entry);

    return val;
  }

  public SharedStruct getStruct(int key) {
    System.out.println("getStruct(" + key + ")");
    return log.get(key);
  }

  public void zip() {
    System.out.println("zip()");
  }

}
~~~

