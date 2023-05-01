# JVM

## 解释和类加载

根据Java 虚拟机规范（VM Spec），JVM是基于栈的解释型机器。JVM不依赖寄存器，而使用一个包含部分结果的执行栈，并通过操作该栈顶额一个或多个值来执行计算。
可以把JVM解释器的基本行为理解为一个`包含在while循环中的switch语句`，按顺序单独处理程序的每一个操作码，使用求值栈保存中间值。真实的JVM产品会更复杂。

### Java类加载机制

类加载器链 bootstrap => extension => application

* 1.启动类加载器（bootstrap classloader）
  包含核心Java运行时中的类，`Java 8`及之前版本，这些类是从rt.jar中加载的。而`Java 9`及以后版本中，运行中已经被模块化，类加载的概念有些差别。
  启动类加载器的要点是获得类的一个最小集合（包括`java.lang.Object`、`Class`和`Classloader`等核心类），以允许`其他类加载器`
  启动系统的其他部分。
  Java将`类加载器`建模为其运行时和类型系统内的对象，所以需要以某种方式将一组初始类加载进来。否则，在定义类加载器时就会出现循环加载。
* 2.扩展类加载器（extension classloader）它将`bootstrap classloader`定义为自己的父加载器，并在需要时将加载工作委托给父加载器。
  扩展类加载器的应用并不广泛，但是可以为具体的操作系统和平台提供重写代码和原生代码。
* 3.应用类加载器（application classloader）
  它负责从指定的类路径（classpath）中加载用户类。它的父加载器是`extension classloader`。

当程序执行过程中遇到对新类的依赖时，Java会加载它们。如果一个classloader没有找到某个类，则加载行为会被委托给其父classloader。
如果链式查找已经找到了`bootstrap classloader`，但还是没有找到该类，则抛出`ClassNotFoundException`异常。

正常情况下，Java只会对一个类加载一次，并在运行时环境中创建一个Class对象来表示它。
<br/><span style="color:orange; ">
需要注意，同一个类有可能被不同的类加载器加载两次。因此，类在系统中是通过`加载它的classloader`以及`其全限定类名`
来识别的。</span>

## 字节码

Java源代码在执行前要经历一系列变换。javac编译阶段
javac的工作是将Java代码转换为包含字节码的.class文件。javac在编译期间很少进行优化，而且使用反编译工具（比如javap）查看生成的字节码时，可读性依然很好，可以像Java代码一样识别。

字节码是一种中间表示，没有与特定的机器架构绑定。 与机器架构解耦的好处：

* 提供可移植性。
* 提供了对Java语音的抽象，为了解JVM执行代码的方式提供了一种重要视角。

JVM对于任何要加载的类，都要先验证其符合指定格式，然后才允许其执行。

类文件剖析

| 组件      | 描述                               |
|---------|----------------------------------|
| 魔数      | 0xCAFEBABE                       |
| 类文件格式版本 | 该类文件的主版本号和此版本号                   |
| 常量池     | 该类的常量池，保存代码中的常量，如类、接口和字段的名字      |
| 访问标志    | 该类是否为抽象类、静态类、是否为public、是否为final等 |
| 当前类     | 该类的名字，指向常量池的索引                   |
| 超类      | 超类的名字，指向常量池的索引                   |
| 接口      | 该类实现的接口，指向常量池的索引                 |
| 字段      | 该类的所有字段                          |
| 方法      | 该类的所有方法                          |
| 属性      | 该类的所有属性（比如，源文件的名字等等）             |

classloader会检查主版本号和次版本号，以确保兼容性；如不兼容，则在运行时抛出UnsupportedClassVersionError，说明运行时的版本低于所编译类文件的版本。

辅助记忆

| My    | Very    | Cute     | Animal | Turns | Savage | In         | Full   | Moon    | Areas      |
|-------|---------|----------|--------|-------|--------|------------|--------|---------|------------|
| M     | V       | C        | A      | T     | S      | I          | F      | M       | A          |
| Magic | Version | Constant | Access | This  | Super  | Interfaces | Fields | Methods | Attributes |

## HotSpot简介

1999年4月，Sun公司向Java引入了性能方面最大的一个变化。HotSpot虚拟机是Java的一个关键特性，使得Java的性能可以与C和C++比肩。
设计Java时，让它`更接近机器`、依赖诸如`零成本抽象`等原则，提高开发人员效率，首选`把事情做完`而不是严格的底层控制。

## JIT简介

Java程序在字节码解释器中开始执行，而在解释器中，指令是在虚拟化的栈式机器上执行的。
但为了获得最好的性能，程序还是必须利用CPU的原生特性，直接在CPU上执行。HotSpot通过将程序单元从解释的字节码编译成原生代码来实现这个目标。
HotSpot虚拟机中的编译单元是方法和循环。这就是所谓的即时编译（JIT）。

JIT编译的原理：当应用程序在解释模式下运行，监控该应用程序，并观察代码中执行最频繁的部分。在这个分析过程中，系统会捕获程序化的轨迹信息，从而实现更复杂的优化。
一旦特定方法的执行超过了一个阈值，剖析器就会对这段特定代码进行编译和优化。

<br/><span style="color:orange; ">在JVM上执行的JIT编译代码（经过优化）可能与原始的Java源代码看上去完全不一样。</span>

## JVM内存管理

Java通过垃圾收集（garbage collection，GC）的进程自动管理堆内存。GC是一个非确定性的过程。
GC付出的代价：当GC运行时，往往会造成`全部停顿`，这意味着当GC进程运行时应用程序会暂停。通常，这些暂停时间设计得非常短，但当应用程序承受压力时，暂定时间可能会增加。

## 线程和Java内存模型

Java最大优势之一是内置了对多线程的支持。且Java环境和JVM一样，本身就是多线程的。这带来了额外的、无法简单化得复杂性，使得性能分析过程更加困难。
<br/><span style="color:orange; ">每个JVM应用程序线程背后都有唯一的操作系统线程支持，它会再我们调用Thread.start()
时被创建</span>

JVM内存模型（Java memory model，JMM）是内存的一个形式化模型，它解释了不同执行线程如何看到对象中保存的正在修改的值。

## 不同的JVM

* OpenJDK
* Oracle
* Zulu
* IcedTea
* Zing
* J9
* Avian
* Android

<br/><span style="color:orange; ">各种基于HotSpot的实现之间基本上没有性能方面的差异。</span>

## 许可证说明

大多数JVM是从基于GPL协议授权的HotSpot衍生出来的。
Oracle Java(从Java 9开始)，尽管来自OpenJDK代码库，但不是开源软件。它提供了一些商用功能和工具。

## JVM监控和工具

* Java管理扩展（Java management extension, JMX）
  一种功能强大的通用技术，用于控制和监控JVM以及在其上运行的应用程序。支持从客户端应用程序中以常规方式修改参数和调用方法。
* Java agent
  一个用Java编写的工具组件，利用`java.lang.instrument`中的接口来修改方法的字节码。
  安装某个代理，需要向JVM提供一个启动标示：`-javaagent:<path-to-agent-jar>=<options>`
  代理的Jar包中必须包含一个清单文件（manifest），并包含Premain-Class属性。此属性包含代理类名称，该类必须实现一个公开的、静态的premain()
  方法，充当Java代理的注册钩子。
* JVM工具接口（JVM tool interface，JVMTI）
  JVM的一个原生接口，使用该接口的代理必须是用原生编译型语言编写（主要是C或C++）。可以将其看作一个通信接口，支持原生代理监控JVM事件并接收事件通知。
  要安装代理，需要的标志：`-agentlib:<agent-lib-name>=<options>`或`-agentpath:<path-to-agent>=<options>`
  虽然`Java agent`写起来容易，但是有些信息是无法通过`Java API`获取的，需要访问这些数据，就只能选择JVMTI。
* The serviceability agent（SA）
  一组API和工具，可以对外公开Java对象和HotSpot数据结构的信息。SA不需要在目标虚拟机中运行任何代码。SA使用符号查找和进程内存读取等基本原语来实现调试功能。
  SA可以调试活跃Java进程以及核心转储文件（也称为崩溃转储文件）。

VisualVM

一个基于NetBeans平台的图形化工具。替代过时的jconsole工具。
VisualVM用于实时监控正在运行的进程，它使用的是JVM attach机制。
本地进程，VisualVM会直接列出进程；远程经常，远端必须接受入站连接（通过JMX），这意味着jstatd必须在远程主机上运行。

