# 配置

Table 和 SQL API 的默认配置能够确保结果准确，同时也提供可接受的性能。

根据 Table 程序的需求，可能需要调整特定的参数用于优化。例如，无界流程序可能需要保证所需的状态是有限的(请参阅 [流式概念]()).

## 概览

当实例化一个 TableEnvironment 时，可以使用 EnvironmentSettings 来传递用于当前会话的所期望的配置项 —— 传递一个
Configuration 对象到 EnvironmentSettings。

此外，在每个 TableEnvironment 中，TableConfig 提供用于当前会话的配置项。

对于常见或者重要的配置项，TableConfig 提供带有详细注释的 getters 和 setters 方法。

对于更加高级的配置，用户可以直接访问底层的 key-value 配置项。以下章节列举了所有可用于调整 Flink Table 和 SQL API 程序的配置项。

注意 因为配置项会在执行操作的不同时间点被读取，所以推荐在实例化 TableEnvironment 后尽早地设置配置项。

### Java

~~~
// instantiate table environment
Configuration configuration = new Configuration();
// set low-level key-value options
configuration.setString("table.exec.mini-batch.enabled", "true");
configuration.setString("table.exec.mini-batch.allow-latency", "5 s");
configuration.setString("table.exec.mini-batch.size", "5000");
EnvironmentSettings settings = EnvironmentSettings.newInstance()
        .inStreamingMode().withConfiguration(configuration).build();
TableEnvironment tEnv = TableEnvironment.create(settings);

// access flink configuration after table environment instantiation
TableConfig tableConfig = tEnv.getConfig();
// set low-level key-value options
tableConfig.set("table.exec.mini-batch.enabled", "true");
tableConfig.set("table.exec.mini-batch.allow-latency", "5 s");
tableConfig.set("table.exec.mini-batch.size", "5000");
~~~

### SQL CLI

~~~
Flink SQL> SET 'table.exec.mini-batch.enabled' = 'true';
Flink SQL> SET 'table.exec.mini-batch.allow-latency' = '5s';
Flink SQL> SET 'table.exec.mini-batch.size' = '5000';
~~~

## 执行配置

以下选项可用于优化查询执行的性能。

## 优化器配置

以下配置可以用于调整查询优化器的行为以获得更好的执行计划。

## Planner 配置

以下配置可以用于调整 planner 的行为。

## SQL Client 配置

以下配置可以用于调整 sql client 的行为。

