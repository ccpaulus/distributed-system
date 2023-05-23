# How to use Maven to configure your project

本指南将向您展示如何使用`Maven`配置`Flink作业项目`，`Maven`是由`Apache Software Foundation`
开发的开源构建自动化工具，使您能够构建、发布和部署项目。您可以使用它来管理软件项目的整个`生命周期`。

## Requirements

* Maven 3.0.4 (or higher)
* Java 8 (deprecated) or Java 11

## Importing the project into your IDE

创建[项目目录和文件]()后，我们建议您将此项目导入到 IDE 进行开发和测试。

IntelliJ IDEA 支持开箱即用的 Maven 项目。Eclipse 提供了 [m2e 插件]() 来 [导入 Maven 项目]()。

<span style="color:orange; ">**_注意_**：对于Flink来说，Java的默认`JVM堆`大小可能太小，您必须手动增加它。在`Eclipse`
中，选择`Run Configurations -> Arguments`，在`VM Arguments`框中写入:`-xmx800m`。在`IntelliJ IDEA`
中，建议从`Help | Edit Custom VM Options`菜单中更改`JVM选项`
。详情请查阅[本文](https://intellij-support.jetbrains.com/hc/en-us/articles/206544869-Configuring-JVM-options-and-platform-properties)。
<br/>**_关于IntelliJ的注意事项_**：要使应用程序在 IntelliJ IDEA
中运行，必须在运行配置中勾选`Include dependencies with "Provided" scope`框。如果这个选项不可用(可能是由于使用较旧的
IntelliJ IDEA 版本)，那么一个变通方法是创建一个调用应用程序的`main()方法`的测试。
</span>

## Building the project

如果您希望`编译/打包`您的项目，需要导航到项目目录并运行`mvn clean package`命令。
您将 **找到一个 JAR 文件** ，其中包含您的应用程序（还有已作为依赖项添加到应用程序中的`connectors`
和`库`）：`target/<artifact-id>-<version>.jar`。

<span style="color:orange; ">**_注意_**：如果使用与`DataStreamJob`不同的类作为应用程序的`main class/entry point`
，我们建议您更改`pom.xml`文件中的`mainClass`设置，这样Flink就可以从JAR文件运行应用程序，而无需额外指定`main class`。</span>

## Adding dependencies to the project

在项目目录中打开`pom.xml`文件，并在`dependencies`之间添加`dependency `。

例如，你可以像这样添加`Kafka connector`作为`dependency`：

~~~
<dependencies>
    
    <dependency>
        <groupId>org.apache.flink</groupId>
        <artifactId>flink-connector-kafka</artifactId>
        <version>1.17.0</version>
    </dependency>
    
</dependencies>
~~~

然后在命令行上执行`mvn install`。

从 Java Project Template、Scala Project Template 或 Gradle 创建的项目被配置为，在运行`mvn clean package`
时自动将应用程序依赖项包含到应用程序JAR中。 对于没有从这些模板中设置的项目，我们建议添加`Maven Shade Plugin`
以将所有必需的依赖项打包进应用程序 jar。

<span style="color:orange; ">**_重要_**:请注意，所有这些`核心API`依赖项都应该将它们的`scope`设置为[provided]()。
这意味着在`compile`时需要它们，但不应该将它们打包到项目的最终应用程序JAR文件中。
如果没有设置为`provided`，最好的情况是最终的JAR变得过大，因为它包含所有`Flink核心依赖项`。
最坏的情况是，添加到应用程序JAR文件中的`Flink核心依赖项`与您自己的一些依赖项出现`版本冲突`(
通常可以通过反向类加载来避免这种情况)。</span>

## Packaging the application

根据您的用例，在将Flink应用程序部署到Flink环境之前，可能需要以不同的方式对其进行打包。

如果您想为Flink Job创建一个JAR，并且只使用Flink依赖项，而不使用任何第三方依赖项(例如：使用JSON格式的`filesystem connector`)
，您不需要创建`uber/fat JAR`或`shade`任何依赖。

如果您想为Flink作业创建一个JAR，并使用Flink发行版中没有内置的外部依赖项。
您可以将它们添加到发行版的`classpath`中，也可以将它们打包进您的`uber/fat JAR`中。

生成的`uber/fat JAR`，可以将其提交到本地或远程集群：

~~~
bin/flink run -c org.example.MyJob myFatJar.jar
~~~

要了解有关如何部署Flink作业的详细信息，请查看[部署指南](https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/deployment/cli/)。

## Template for creating an uber/fat JAR with dependencies

要构建包含声明的`connectors`和`库`所需的所有依赖项的应用程序JAR，您可以使用以下插件定义：

~~~
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-shade-plugin</artifactId>
            <version>3.1.1</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>shade</goal>
                    </goals>
                    <configuration>
                        <artifactSet>
                            <excludes>
                                <exclude>com.google.code.findbugs:jsr305</exclude>
                            </excludes>
                        </artifactSet>
                        <filters>
                            <filter>
                                <!-- Do not copy the signatures in the META-INF folder.
                                Otherwise, this might cause SecurityExceptions when using the JAR. -->
                                <artifact>*:*</artifact>
                                <excludes>
                                    <exclude>META-INF/*.SF</exclude>
                                    <exclude>META-INF/*.DSA</exclude>
                                    <exclude>META-INF/*.RSA</exclude>
                                </excludes>
                            </filter>
                        </filters>
                        <transformers>
                            <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                                <!-- Replace this with the main class of your job -->
                                <mainClass>my.programs.main.clazz</mainClass>
                            </transformer>
                            <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer"/>
                        </transformers>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
~~~

默认情况下，[Maven shade plugin](https://maven.apache.org/plugins/maven-shade-plugin/index.html)将包括`runtime`
和`compile`范围中的所有依赖项。

