# Kubernetes 安装

## 入门

本 _入门_ 指南描述了如何在 [Kubernetes]() 上部署 Flink Session 集群。

### 介绍

本文描述了如何使用 Flink standalone 部署模式在 Kubernetes 上部署 [standalone]() 模式的 Flink
集群。通常我们建议新用户使用 [native Kubernetes 部署]()模式在 Kubernetes上部署 Flink。

### 准备

本指南假设存在一个 Kubernets 的运行环境。你可以通过运行 `kubectl get nodes` 命令来确保 Kubernetes 环境运行正常，该命令展示所有连接到
Kubernets 集群的 node 节点信息。

如果你想在本地运行 Kubernetes，建议使用 [MiniKube]()。

如果使用 MiniKube，请确保在部署 Flink 集群之前先执行 `minikube ssh 'sudo ip link set docker0 promisc on'`，否则 Flink
组件不能自动地将自己映射到 Kubernetes Service 中。

### Kubernetes 上的 Flink session 集群

Flink session 集群 是以一种长期运行的 Kubernetes Deployment 形式执行的。你可以在一个 session 集群 上运行多个 Flink
作业。当然，只有 session 集群部署好以后才可以在上面提交 Flink 作业。

在 Kubernetes 上部署一个基本的 Flink session 集群 时，一般包括下面三个组件：

* 运行 [JobManager]() 的 Deployment；
* 运行 [TaskManagers]() 的 Deployment；
* 暴露 JobManager 上 REST 和 UI 端口的 Service；

使用[通用集群资源定义]()中提供的文件内容来创建以下文件，并使用 kubectl 命令来创建相应的组件：

~~~
    # Configuration 和 service 的定义
    $ kubectl create -f flink-configuration-configmap.yaml
    $ kubectl create -f jobmanager-service.yaml
    # 为集群创建 deployment
    $ kubectl create -f jobmanager-session-deployment.yaml
    $ kubectl create -f taskmanager-session-deployment.yaml
~~~

接下来，我们设置端口转发以访问 Flink UI 页面并提交作业：

1. 运行 `kubectl port-forward ${flink-jobmanager-pod} 8081:8081` 将 jobmanager 的 web ui 端口映射到本地 8081。
2. 在浏览器中导航到 http://localhost:8081 页面。
3. 此外，也可以使用如下命令向集群提交作业：
    ~~~
    $ ./bin/flink run -m localhost:8081 ./examples/streaming/TopSpeedWindowing.jar
    ~~~

可以使用以下命令停止运行 flink 集群：

~~~
    $ kubectl delete -f jobmanager-service.yaml
    $ kubectl delete -f flink-configuration-configmap.yaml
    $ kubectl delete -f taskmanager-session-deployment.yaml
    $ kubectl delete -f jobmanager-session-deployment.yaml
~~~

## 部署模式

### Application 集群模式

_Flink Application_ 集群 是运行单个 Application 的专用集群，部署集群时要保证该 Application 可用。

在 Kubernetes 上部署一个基本的 Flink Application 集群 时，一般包括下面三个组件：

* 一个运行 JobManager 的 Application；
* 运行若干个 TaskManager 的 Deployment；
* 暴露 JobManager 上 REST 和 UI 端口的 Service；

检查 [Application 集群资源定义]() 并做出相应的调整：

`jobmanager-job.yaml` 中的 args 属性必须指定用户作业的主类。也可以参考[如何设置 JobManager 参数]()
来了解如何将额外的 `args` 传递给 `jobmanager-job.yaml` 配置中指定的 Flink 镜像。

`job artifacts` 参数必须可以从 [资源定义示例]() 中的 `job-artifacts-volume` 处获取。假如是在 minikube 集群中创建这些组件，那么定义示例中的
job-artifacts-volume 可以挂载为主机的本地目录。如果不使用 minikube 集群，那么可以使用 Kubernetes 集群中任何其它可用类型的
volume 来提供 `job artifacts`。此外，还可以构建一个已经包含 `job artifacts` 参数的[自定义镜像]()。

在创建[通用集群组件]()后，指定 [Application 集群资源定义]()文件，执行 `kubectl` 命令来启动 Flink Application 集群：

~~~
    $ kubectl create -f jobmanager-job.yaml
    $ kubectl create -f taskmanager-job-deployment.yaml
~~~

要停止单个 application 集群，可以使用 kubectl 命令来删除相应组件以及 [通用集群资源]()对应的组件 ：

~~~
    $ kubectl delete -f taskmanager-job-deployment.yaml
    $ kubectl delete -f jobmanager-job.yaml
~~~

### Per-Job 集群模式

在 Kubernetes 上部署 Standalone 集群时不支持 Per-Job 集群模式。

### Session 集群模式

本文档开始部分的[入门]()指南中描述了 Session 集群模式的部署。

## Kubernetes 上运行 Standalone 集群指南

### Configuration

所有配置项都展示在[配置页面]()上。在 config map 配置文件 `flink-configuration-configmap.yaml`
中，可以将配置添加在 `flink-conf.yaml` 部分。

### 在 Kubernets 上访问 Flink

接下来可以访问 Flink UI 页面并通过不同的方式提交作业：

* `kubectl proxy`:
    1. 在终端运行 `kubectl proxy` 命令。
    2. 在浏览器中导航到 http://localhost:8001/api/v1/namespaces/default/services/flink-jobmanager:webui/proxy。
* `kubectl port-forward`:
    1. 运行 kubectl port-forward ${flink-jobmanager-pod} 8081:8081 将 jobmanager 的 web ui 端口映射到本地的 8081。
    2. 在浏览器中导航到 http://localhost:8081。
    3. 此外，也可以使用如下命令向集群提交作业：
       ~~~
       $ ./bin/flink run -m localhost:8081 ./examples/streaming/TopSpeedWindowing.jar
       ~~~
* 基于 jobmanager 的 rest 服务上创建 `NodePort` service：

    1. 运行 `kubectl create -f jobmanager-rest-service.yaml` 来基于 jobmanager 创建 `NodePort`
       service。`jobmanager-rest-service.yaml` 的示例文件可以在 [附录]() 中找到。
    2. 运行 `kubectl get svc flink-jobmanager-rest` 来查询 server 的 `node-port`，然后再浏览器导航到 http://<
       public-node-ip>:<node-port>。
    3. 如果使用 minikube 集群，可以执行 `minikube ip` 命令来查看 public ip。
    4. 与 `port-forward` 方案类似，也可以使用如下命令向集群提交作业。
        ~~~
        $ ./bin/flink run -m <public-node-ip>:<node-port> ./examples/streaming/TopSpeedWindowing.jar
        ~~~

### 调试和访问日志

通过查看 Flink 的日志文件，可以很轻松地发现许多常见错误。如果你有权访问 Flink 的 Web 用户界面，那么可以在页面上访问
JobManager 和 TaskManager 日志。

如果启动 Flink 出现问题，也可以使用 Kubernetes 工具集访问日志。使用 `kubectl get pods` 命令查看所有运行的 pods
资源。针对上面的快速入门示例，你可以看到三个 pod：

~~~
$ kubectl get pods
NAME                                 READY   STATUS             RESTARTS   AGE
flink-jobmanager-589967dcfc-m49xv    1/1     Running            3          3m32s
flink-taskmanager-64847444ff-7rdl4   1/1     Running            3          3m28s
flink-taskmanager-64847444ff-nnd6m   1/1     Running            3          3m28s
~~~

现在你可以通过运行 `kubectl logs flink-jobmanager-589967dcfc-m49xv` 来访问日志。

### 高可用的 Standalone Kubernetes

对于在 Kubernetes 上实现HA，可以参考当前的 [Kubernets 高可用服务]()。

#### Kubernetes 高可用 Services

Session 模式和 Application 模式集群都支持使用 Kubernetes 高可用服务。需要在 `flink-configuration-configmap.yaml` 中添加如下
Flink 配置项。

Note 配置了 HA 存储目录相对应的文件系统必须在运行时可用。请参阅[自定义Flink 镜像]()和[启用文件系统插件]()获取更多相关信息。

~~~
apiVersion: v1
kind: ConfigMap
metadata:
  name: flink-config
  labels:
    app: flink
data:
  flink-conf.yaml: |+
  ...
    kubernetes.cluster-id: <cluster-id>
    high-availability.type: kubernetes
    high-availability.storageDir: hdfs:///flink/recovery
    restart-strategy.type: fixed-delay
    restart-strategy.fixed-delay.attempts: 10
  ...  
~~~

此外，你必须使用具有创建、编辑、删除 ConfigMap 权限的 service 账号启动 JobManager 和 TaskManager
pod。请查看[如何为 pod 配置 service 账号]()获取更多信息。

当启用了高可用，Flink 会使用自己的 HA 服务进行服务发现。因此，JobManager Pod 会使用 IP 地址而不是 Kubernetes 的 service
名称来作为 `jobmanager.rpc.address` 的配置项启动。完整配置请参考[附录]()。

#### Standby JobManagers

通常，只启动一个 JobManager pod 就足够了，因为一旦 pod 崩溃，Kubernetes
就会重新启动它。如果要实现更快的恢复，需要将 `jobmanager-session-deployment-ha.yaml` 中的 replicas 配置
或 `jobmanager-application-ha.yaml` 中的 `parallelism` 配置设定为大于 1 的整型值来启动 Standby JobManagers。

### 启用 Queryable State

如果你为 TaskManager 创建了 `NodePort` service，那么你就可以访问 TaskManager 的 Queryable State 服务：

1. 运行 `kubectl create -f taskmanager-query-state-service.yaml` 来为 taskmanager pod 创建 NodePort
   service。`taskmanager-query-state-service.yaml` 的示例文件可以从[附录]()中找到。
2. 运行 `kubectl get svc flink-taskmanager-query-state` 来查询 service 对应 node-port
   的端口号。然后你就可以创建 [QueryableStateClient(<public-node-ip>, <node-port>]() 来提交状态查询。

### 在 Reactive 模式下使用 Standalone Kubernetes

[Reactive Mode]() 允许在 _Application 集群_ 始终根据可用资源调整作业并行度的模式下运行 Flink。与 Kubernetes
结合使用，TaskManager
部署的副本数决定了可用资源。增加副本数将扩大作业规模，而减少副本数将会触发缩减作业规模。通过使用 [Horizontal Pod Autoscaler]()
也可以自动实现该功能。

要在 Kubernetes 上使用 Reactive Mode，请按照[使用 Application 集群部署作业]()
完成相同的步骤。但是要使用 `flink-reactive-mode-configuration-configmap.yaml`
配置文件来代替 `flink-configuration-configmap.yaml`。该文件包含了针对 Flink 的 `scheduler-mode: reactive` 配置。

一旦你部署了 _Application 集群_，就可以通过修改 `flink-taskmanager` 的部署副本数量来扩大或缩小作业的并行度。

## 附录

### 通用集群资源定义

`flink-configuration-configmap.yaml`

~~~
apiVersion: v1
kind: ConfigMap
metadata:
  name: flink-config
  labels:
    app: flink
data:
  flink-conf.yaml: |+
    jobmanager.rpc.address: flink-jobmanager
    taskmanager.numberOfTaskSlots: 2
    blob.server.port: 6124
    jobmanager.rpc.port: 6123
    taskmanager.rpc.port: 6122
    queryable-state.proxy.ports: 6125
    jobmanager.memory.process.size: 1600m
    taskmanager.memory.process.size: 1728m
    parallelism.default: 2    
  log4j-console.properties: |+
    # 如下配置会同时影响用户代码和 Flink 的日志行为
    rootLogger.level = INFO
    rootLogger.appenderRef.console.ref = ConsoleAppender
    rootLogger.appenderRef.rolling.ref = RollingFileAppender

    # 如果你只想改变 Flink 的日志行为则可以取消如下的注释部分
    #logger.flink.name = org.apache.flink
    #logger.flink.level = INFO

    # 下面几行将公共 libraries 或 connectors 的日志级别保持在 INFO 级别。
    # root logger 的配置不会覆盖此处配置。
    # 你必须手动修改这里的日志级别。
    logger.akka.name = akka
    logger.akka.level = INFO
    logger.kafka.name= org.apache.kafka
    logger.kafka.level = INFO
    logger.hadoop.name = org.apache.hadoop
    logger.hadoop.level = INFO
    logger.zookeeper.name = org.apache.zookeeper
    logger.zookeeper.level = INFO

    # 将所有 info 级别的日志输出到 console
    appender.console.name = ConsoleAppender
    appender.console.type = CONSOLE
    appender.console.layout.type = PatternLayout
    appender.console.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n

    # 将所有 info 级别的日志输出到指定的 rolling file
    appender.rolling.name = RollingFileAppender
    appender.rolling.type = RollingFile
    appender.rolling.append = false
    appender.rolling.fileName = ${sys:log.file}
    appender.rolling.filePattern = ${sys:log.file}.%i
    appender.rolling.layout.type = PatternLayout
    appender.rolling.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n
    appender.rolling.policies.type = Policies
    appender.rolling.policies.size.type = SizeBasedTriggeringPolicy
    appender.rolling.policies.size.size=100MB
    appender.rolling.strategy.type = DefaultRolloverStrategy
    appender.rolling.strategy.max = 10

    # 关闭 Netty channel handler 中不相关的（错误）警告
    logger.netty.name = org.jboss.netty.channel.DefaultChannelPipeline
    logger.netty.level = OFF    
~~~

`flink-reactive-mode-configuration-configmap.yaml`

~~~
apiVersion: v1
kind: ConfigMap
metadata:
  name: flink-config
  labels:
    app: flink
data:
  flink-conf.yaml: |+
    jobmanager.rpc.address: flink-jobmanager
    taskmanager.numberOfTaskSlots: 2
    blob.server.port: 6124
    jobmanager.rpc.port: 6123
    taskmanager.rpc.port: 6122
    queryable-state.proxy.ports: 6125
    jobmanager.memory.process.size: 1600m
    taskmanager.memory.process.size: 1728m
    parallelism.default: 2
    scheduler-mode: reactive
    execution.checkpointing.interval: 10s    
  log4j-console.properties: |+
    # 如下配置会同时影响用户代码和 Flink 的日志行为
    rootLogger.level = INFO
    rootLogger.appenderRef.console.ref = ConsoleAppender
    rootLogger.appenderRef.rolling.ref = RollingFileAppender

    # 如果你只想改变 Flink 的日志行为则可以取消如下的注释部分
    #logger.flink.name = org.apache.flink
    #logger.flink.level = INFO


    # 下面几行将公共 libraries 或 connectors 的日志级别保持在 INFO 级别。
    # root logger 的配置不会覆盖此处配置。
    # 你必须手动修改这里的日志级别。
    logger.akka.name = akka
    logger.akka.level = INFO
    logger.kafka.name= org.apache.kafka
    logger.kafka.level = INFO
    logger.hadoop.name = org.apache.hadoop
    logger.hadoop.level = INFO
    logger.zookeeper.name = org.apache.zookeeper
    logger.zookeeper.level = INFO

    # 将所有 info 级别的日志输出到 console
    appender.console.name = ConsoleAppender
    appender.console.type = CONSOLE
    appender.console.layout.type = PatternLayout
    appender.console.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n

    # 将所有 info 级别的日志输出到指定的 rolling file
    appender.rolling.name = RollingFileAppender
    appender.rolling.type = RollingFile
    appender.rolling.append = false
    appender.rolling.fileName = ${sys:log.file}
    appender.rolling.filePattern = ${sys:log.file}.%i
    appender.rolling.layout.type = PatternLayout
    appender.rolling.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n
    appender.rolling.policies.type = Policies
    appender.rolling.policies.size.type = SizeBasedTriggeringPolicy
    appender.rolling.policies.size.size=100MB
    appender.rolling.strategy.type = DefaultRolloverStrategy
    appender.rolling.strategy.max = 10

    # 关闭 Netty channel handler 中不相关的（错误）警告
    logger.netty.name = org.jboss.netty.channel.DefaultChannelPipeline
    logger.netty.level = OFF    
~~~

`jobmanager-service.yaml`。可选的 service，仅在非 HA 模式下需要。

~~~
apiVersion: v1
kind: Service
metadata:
  name: flink-jobmanager
spec:
  type: ClusterIP
  ports:
  - name: rpc
    port: 6123
  - name: blob-server
    port: 6124
  - name: webui
    port: 8081
  selector:
    app: flink
    component: jobmanager
~~~

`jobmanager-rest-service.yaml`。可选的 service，该 service 将 jobmanager 的 rest 端口暴露为公共 Kubernetes node 的节点端口。

~~~
apiVersion: v1
kind: Service
metadata:
  name: flink-jobmanager-rest
spec:
  type: NodePort
  ports:
  - name: rest
    port: 8081
    targetPort: 8081
    nodePort: 30081
  selector:
    app: flink
    component: jobmanager
~~~

`taskmanager-query-state-service.yaml`。可选的 service，该 service 将 TaskManager 的端口暴露为公共 Kubernetes node
的节点端口，通过该端口来访问 queryable state 服务。

~~~
apiVersion: v1
kind: Service
metadata:
  name: flink-taskmanager-query-state
spec:
  type: NodePort
  ports:
  - name: query-state
    port: 6125
    targetPort: 6125
    nodePort: 30025
  selector:
    app: flink
    component: taskmanager
~~~

### Session 集群资源定义

`jobmanager-session-deployment-non-ha.yaml`

~~~
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flink-jobmanager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flink
      component: jobmanager
  template:
    metadata:
      labels:
        app: flink
        component: jobmanager
    spec:
      containers:
      - name: jobmanager
        image: apache/flink:1.17.0-scala_2.12
        args: ["jobmanager"]
        ports:
        - containerPort: 6123
          name: rpc
        - containerPort: 6124
          name: blob-server
        - containerPort: 8081
          name: webui
        livenessProbe:
          tcpSocket:
            port: 6123
          initialDelaySeconds: 30
          periodSeconds: 60
        volumeMounts:
        - name: flink-config-volume
          mountPath: /opt/flink/conf
        securityContext:
          runAsUser: 9999  # 参考官方 flink 镜像中的 _flink_ 用户，如有必要可以修改
      volumes:
      - name: flink-config-volume
        configMap:
          name: flink-config
          items:
          - key: flink-conf.yaml
            path: flink-conf.yaml
          - key: log4j-console.properties
            path: log4j-console.properties
~~~

`jobmanager-session-deployment-ha.yaml`

~~~
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flink-jobmanager
spec:
  replicas: 1 # 通过设置大于 1 的整型值来开启 Standby JobManager
  selector:
    matchLabels:
      app: flink
      component: jobmanager
  template:
    metadata:
      labels:
        app: flink
        component: jobmanager
    spec:
      containers:
      - name: jobmanager
        image: apache/flink:1.17.0-scala_2.12
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        # 下面的 args 参数会使用 POD_IP 对应的值覆盖 config map 中 jobmanager.rpc.address 的属性值。
        args: ["jobmanager", "$(POD_IP)"]
        ports:
        - containerPort: 6123
          name: rpc
        - containerPort: 6124
          name: blob-server
        - containerPort: 8081
          name: webui
        livenessProbe:
          tcpSocket:
            port: 6123
          initialDelaySeconds: 30
          periodSeconds: 60
        volumeMounts:
        - name: flink-config-volume
          mountPath: /opt/flink/conf
        securityContext:
          runAsUser: 9999  # 参考官方 flink 镜像中的 _flink_ 用户，如有必要可以修改
      serviceAccountName: flink-service-account # 拥有创建、编辑、删除 ConfigMap 权限的 Service 账号
      volumes:
      - name: flink-config-volume
        configMap:
          name: flink-config
          items:
          - key: flink-conf.yaml
            path: flink-conf.yaml
          - key: log4j-console.properties
            path: log4j-console.properties
~~~

`taskmanager-session-deployment.yaml`

~~~
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flink-taskmanager
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flink
      component: taskmanager
  template:
    metadata:
      labels:
        app: flink
        component: taskmanager
    spec:
      containers:
      - name: taskmanager
        image: apache/flink:1.17.0-scala_2.12
        args: ["taskmanager"]
        ports:
        - containerPort: 6122
          name: rpc
        - containerPort: 6125
          name: query-state
        livenessProbe:
          tcpSocket:
            port: 6122
          initialDelaySeconds: 30
          periodSeconds: 60
        volumeMounts:
        - name: flink-config-volume
          mountPath: /opt/flink/conf/
        securityContext:
          runAsUser: 9999  # 参考官方 flink 镜像中的 _flink_ 用户，如有必要可以修改
      volumes:
      - name: flink-config-volume
        configMap:
          name: flink-config
          items:
          - key: flink-conf.yaml
            path: flink-conf.yaml
          - key: log4j-console.properties
            path: log4j-console.properties
~~~

### Application 集群资源定义

`jobmanager-application-non-ha.yaml`

~~~
apiVersion: batch/v1
kind: Job
metadata:
  name: flink-jobmanager
spec:
  template:
    metadata:
      labels:
        app: flink
        component: jobmanager
    spec:
      restartPolicy: OnFailure
      containers:
        - name: jobmanager
          image: apache/flink:1.17.0-scala_2.12
          env:
          args: ["standalone-job", "--job-classname", "com.job.ClassName", <optional arguments>, <job arguments>] # 可选的参数项: ["--job-id", "<job id>", "--fromSavepoint", "/path/to/savepoint", "--allowNonRestoredState"]
          ports:
            - containerPort: 6123
              name: rpc
            - containerPort: 6124
              name: blob-server
            - containerPort: 8081
              name: webui
          livenessProbe:
            tcpSocket:
              port: 6123
            initialDelaySeconds: 30
            periodSeconds: 60
          volumeMounts:
            - name: flink-config-volume
              mountPath: /opt/flink/conf
            - name: job-artifacts-volume
              mountPath: /opt/flink/usrlib
          securityContext:
            runAsUser: 9999  # 参考官方 flink 镜像中的 _flink_ 用户，如有必要可以修改
      volumes:
        - name: flink-config-volume
          configMap:
            name: flink-config
            items:
              - key: flink-conf.yaml
                path: flink-conf.yaml
              - key: log4j-console.properties
                path: log4j-console.properties
        - name: job-artifacts-volume
          hostPath:
            path: /host/path/to/job/artifacts
~~~

`jobmanager-application-ha.yaml`

~~~
apiVersion: batch/v1
kind: Job
metadata:
  name: flink-jobmanager
spec:
  parallelism: 1 # 通过设置大于 1 的整型值来开启 Standby JobManager
  template:
    metadata:
      labels:
        app: flink
        component: jobmanager
    spec:
      restartPolicy: OnFailure
      containers:
        - name: jobmanager
          image: apache/flink:1.17.0-scala_2.12
          env:
          - name: POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          # 下面的 args 参数会使用 POD_IP 对应的值覆盖 config map 中 jobmanager.rpc.address 的属性值。
          args: ["standalone-job", "--host", "$(POD_IP)", "--job-classname", "com.job.ClassName", <optional arguments>, <job arguments>] # 可选参数项: ["--job-id", "<job id>", "--fromSavepoint", "/path/to/savepoint", "--allowNonRestoredState"]
          ports:
            - containerPort: 6123
              name: rpc
            - containerPort: 6124
              name: blob-server
            - containerPort: 8081
              name: webui
          livenessProbe:
            tcpSocket:
              port: 6123
            initialDelaySeconds: 30
            periodSeconds: 60
          volumeMounts:
            - name: flink-config-volume
              mountPath: /opt/flink/conf
            - name: job-artifacts-volume
              mountPath: /opt/flink/usrlib
          securityContext:
            runAsUser: 9999  # 参考官方 flink 镜像中的 _flink_ 用户，如有必要可以修改
      serviceAccountName: flink-service-account # 拥有创建、编辑、删除 ConfigMap 权限的 Service 账号
      volumes:
        - name: flink-config-volume
          configMap:
            name: flink-config
            items:
              - key: flink-conf.yaml
                path: flink-conf.yaml
              - key: log4j-console.properties
                path: log4j-console.properties
        - name: job-artifacts-volume
          hostPath:
            path: /host/path/to/job/artifacts
~~~

`taskmanager-job-deployment.yaml`

~~~
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flink-taskmanager
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flink
      component: taskmanager
  template:
    metadata:
      labels:
        app: flink
        component: taskmanager
    spec:
      containers:
      - name: taskmanager
        image: apache/flink:1.17.0-scala_2.12
        env:
        args: ["taskmanager"]
        ports:
        - containerPort: 6122
          name: rpc
        - containerPort: 6125
          name: query-state
        livenessProbe:
          tcpSocket:
            port: 6122
          initialDelaySeconds: 30
          periodSeconds: 60
        volumeMounts:
        - name: flink-config-volume
          mountPath: /opt/flink/conf/
        - name: job-artifacts-volume
          mountPath: /opt/flink/usrlib
        securityContext:
          runAsUser: 9999  # 参考官方 flink 镜像中的 _flink_ 用户，如有必要可以修改
      volumes:
      - name: flink-config-volume
        configMap:
          name: flink-config
          items:
          - key: flink-conf.yaml
            path: flink-conf.yaml
          - key: log4j-console.properties
            path: log4j-console.properties
      - name: job-artifacts-volume
        hostPath:
          path: /host/path/to/job/artifacts
~~~

