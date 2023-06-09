# Amazon S3

[Amazon Simple Storage Service]() (Amazon S3) 提供用于多种场景的云对象存储。S3 可与 Flink
一起使用以读取、写入数据，并可与 [流的 State backends]() 相结合使用。

通过以下格式指定路径，S3 对象可类似于普通文件使用：

~~~
s3://<your-bucket>/<endpoint>
~~~

Endpoint 可以是一个文件或目录，例如：

~~~
// 读取 S3 bucket
env.readTextFile("s3://<bucket>/<endpoint>");

// 写入 S3 bucket
stream.writeAsText("s3://<bucket>/<endpoint>");

// 使用 S3 作为 FsStatebackend
env.setStateBackend(new FsStateBackend("s3://<your-bucket>/<endpoint>"));
~~~

注意这些例子并不详尽，S3 同样可以用在其他场景，包括 [JobManager 高可用配置]() 或 [RocksDBStateBackend]()，以及所有 Flink
需要使用文件系统 URI 的位置。

在大部分使用场景下，可使用 flink-s3-fs-hadoop 或 flink-s3-fs-presto 两个独立且易于设置的 S3 文件系统插件。然而在某些情况下，例如使用
S3 作为 YARN 的资源存储目录时，可能需要配置 Hadoop S3 文件系统。

### Hadoop/Presto S3 文件系统插件

如果您在使用 [Flink on EMR]()，您无需手动对此进行配置。

Flink 提供两种文件系统用来与 S3 交互：flink-s3-fs-presto 和 flink-s3-fs-hadoop。两种实现都是独立的且没有依赖项，因此使用时无需将
Hadoop 添加至 classpath。

flink-s3-fs-presto，通过 s3:// 和 s3p:// 两种 scheme 使用，基于 [Presto project]()。
可以使用[和 Presto 文件系统相同的配置项]()进行配置，方式为将配置添加到 flink-conf.yaml 文件中。如果要在 S3 中使用
checkpoint，推荐使用 Presto S3 文件系统。

flink-s3-fs-hadoop，通过 s3:// 和 s3a:// 两种 scheme 使用, 基于 [Hadoop Project]()。
本文件系统可以使用类似 [Hadoop S3A 的配置项]()进行配置，方式为将配置添加到 flink-conf.yaml 文件中。

例如，Hadoop 有 fs.s3a.connection.maximum 的配置选项。 如果你想在 Flink 程序中改变该配置的值，你需要将配置
s3.connection.maximum: xyz 添加到 flink-conf.yaml 文件中。Flink 会内部将其转换成配置 fs.s3a.connection.maximum。 而无需通过
Hadoop 的 XML 配置文件来传递参数。

另外，它是唯一支持 [FileSystem]() 的 S3 文件系统。

flink-s3-fs-hadoop 和 flink-s3-fs-presto 都为 s3:// scheme 注册了默认的文件系统包装器，flink-s3-fs-hadoop 另外注册了 s3a:
//，flink-s3-fs-presto 注册了 s3p://，因此二者可以同时使用。 例如某作业使用了 [FileSystem]()，它仅支持 Hadoop，但建立
checkpoint 使用 Presto。在这种情况下，建议明确地使用 s3a:// 作为 sink (Hadoop) 的 scheme，checkpoint (Presto) 使用 s3p:
//。这一点对于 [FileSystem]() 同样成立。

在启动 Flink 之前，将对应的 JAR 文件从 opt 复制到 Flink 发行版的 plugins 目录下，以使用 flink-s3-fs-hadoop 或
flink-s3-fs-presto。

~~~
mkdir ./plugins/s3-fs-presto
cp ./opt/flink-s3-fs-presto-1.17.0.jar ./plugins/s3-fs-presto/
~~~

### 配置访问凭据

在设置好 S3 文件系统包装器后，您需要确认 Flink 具有访问 S3 Bucket 的权限。

#### Identity and Access Management (IAM)（推荐使用）

建议通过 [Identity and Access Management (IAM)]() 来配置 AWS 凭据。可使用 IAM 功能为 Flink 实例安全地提供访问 S3 Bucket
所需的凭据。关于配置的细节超出了本文档的范围，请参考 AWS 用户手册中的 [IAM Roles]() 部分。

如果配置正确，则可在 AWS 中管理对 S3 的访问，而无需为 Flink 分发任何访问密钥（Access Key）。

#### 访问密钥（Access Key）（不推荐）

可以通过**访问密钥对（access and secret key）**授予 S3 访问权限。请注意，根据 [Introduction of IAM roles]()，不推荐使用该方法。

s3.access-key 和 s3.secret-key 均需要在 Flink 的 flink-conf.yaml 中进行配置：

~~~
s3.access-key: your-access-key
s3.secret-key: your-secret-key
~~~

## 配置非 S3 访问点

S3 文件系统还支持兼容 S3 的对象存储服务，如 [IBM’s Cloud Object Storage]() 和 [Minio]()。可在 flink-conf.yaml 中配置使用的访问点：

~~~
s3.endpoint: your-endpoint-hostname
~~~

## 配置路径样式的访问

某些兼容 S3 的对象存储服务可能没有默认启用虚拟主机样式的寻址。这种情况下需要在 flink-conf.yaml 中添加配置以启用路径样式的访问：

~~~
s3.path.style.access: true
~~~

## S3 文件系统的熵注入

内置的 S3 文件系统 (flink-s3-fs-presto and flink-s3-fs-hadoop) 支持熵注入。熵注入是通过在关键字开头附近添加随机字符，以提高
AWS S3 bucket 可扩展性的技术。

如果熵注入被启用，路径中配置好的字串将会被随机字符所替换。例如路径 s3://my-bucket/_entropy_/checkpoints/dashboard-job/
将会被替换成类似于 s3://my-bucket/gf36ikvg/checkpoints/dashboard-job/ 的路径。 `这仅在使用熵注入选项创建文件时启用！`
否则将完全删除文件路径中的 entropy key。更多细节请参见 [FileSystem.create(Path, WriteOption)]()。

目前 Flink 运行时仅对 checkpoint 数据文件使用熵注入选项。所有其他文件包括 checkpoint 元数据与外部 URI 都不使用熵注入，以保证
checkpoint URI 的可预测性。

配置 entropy key 与 entropy length 参数以启用熵注入：

~~~
s3.entropy.key: _entropy_
s3.entropy.length: 4 (default)
~~~

s3.entropy.key 定义了路径中被随机字符替换掉的字符串。不包含 entropy key 路径将保持不变。 如果文件系统操作没有经过 “熵注入”
写入，entropy key 字串将被直接移除。 s3.entropy.length 定义了用于熵注入的随机字母/数字字符的数量。

