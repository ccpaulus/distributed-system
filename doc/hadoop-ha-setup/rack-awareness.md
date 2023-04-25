# 机架感知

## 说明

Hadoop组件是机架感知的。例如，HDFS块放置将通过在不同的机架上放置一个块副本来使用机架感知来容错。这提供了在网络交换机故障或集群内分区时的数据可用性。

例：

~~~
在hdfs集群中，文件存储是分成多个block块存储，一个block块默认的大小为128M。
为了保证hadoop集群的高效性和安全性，每个block快会备份多个副本，副本个数默认为3个。
在没有配置机架感知的情况下，客户端上传文件到HDFS上时，block是随机存储在不同的服务器。这样就无法优化服务器间的通信效率。
如果随机分配到同一个机架内，那如果这个机架断电，那么就会存在安全性问题。

hadoop机架感知策略：
当客户端上次文件到HDFS上
1、文件的block第一个副本存储在客户端链接的服务器上
2、block第二个副本会存储在不同机架内的随机一个服务器上
3、block第三个副本存储在与第二个副本相同机架内不同的服务器上
更多副本随机节点存储
~~~

## 配置

在namenode的`core-site.xml`加属性`topology.script.file.name`配置脚本的位置

<span style="color: green; ">`namenode`
启动时，会判断该配置选项是否为空，如果非空，则表示已经用机架感知的配置，此时`namenode`会根据配置寻找该脚本，
并在接收到每一个`datanode`的`heartbeat`时，将该`datanode`的`ip`地址作为参数传给该脚本运行，并将得到的输出作为该`datanode`
所属的机架，保存到内存的一个`map`中。
</span>

~~~
<property>
    <name>topology.script.file.name</name>
    <value>#{HADOOP_HOME}/etc/hadoop/topology.sh</value>
</property>
~~~

### bash 脚本

<span style="color: red; ">
脚本的编写，需要将真实的网络拓朴和机架信息了解清楚后，通过该脚本将机器的ip地址和机器名正确的映射到相应的机架上去</span>

<span style="color: green; ">执行脚本，入参`IP | hostname`，能得到内容`例：/dc1/rack1`，即表示正确</span>

~~~
#!/bin/bash
# Here's a bash example to show just how simple these scripts can be
# Assuming we have flat network with everything on a single switch, we can fake a rack topology.
# This could occur in a lab environment where we have limited nodes,like 2-8 physical machines on a unmanaged switch.
# This may also apply to multiple virtual machines running on the same physical hardware.
# The number of machines isn't important, but that we are trying to fake a network topology when there isn't one.
#
#       +----------+    +--------+
#       |jobtracker|    |datanode|
#       +----------+    +--------+
#              \        /
#  +--------+  +--------+  +--------+
#  |datanode|--| switch |--|datanode|
#  +--------+  +--------+  +--------+
#              /        \
#       +--------+    +--------+
#       |datanode|    |namenode|
#       +--------+    +--------+
#
# With this network topology, we are treating each host as a rack.  This is being done by taking the last octet
# in the datanode's IP and prepending it with the word '/rack-'.  The advantage for doing this is so HDFS
# can create its 'off-rack' block copy.
# 1) 'echo $@' will echo all ARGV values to xargs.
# 2) 'xargs' will enforce that we print a single argv value per line
# 3) 'awk' will split fields on dots and append the last field to the string '/rack-'. If awk
#    fails to split on four dots, it will still print '/rack-' last field value

#echo $@ | xargs -n 1 | awk -F '.' '{print "/rack-"$NF}'

# 记录node节点配置文件存放的位置

HADOOP_CONF=#{HADOOP_HOME}/etc/hadoop
while [ $# -gt 0 ]
do
nodeArg=$1

# 将文件作为标准输入

exec<${HADOOP_CONF}/topology.data
result=""
while read line
do
ar=($line)
if [ "${ar[0]}"="$nodeArg" ] || [ "${ar[1]}"="$nodeArg" ]
then
result="${ar[2]}"
fi
done
shift

# 输出

if [ -z "$result" ]
then
echo -n "/default-rack"
else
echo -n "$result"
fi
done
~~~

### topology.data

<span style="color: red; ">tips1：该文件中的节点必须使用IP，仅配置主机名无效</span>

<span style="color: red; ">tips2：新增节点时，需同步修改改文件，否则节点启动异常</span>

~~~
# 格式：节点ip 主机名 /交换机xx/机架xx

10.93.80.7 host1093807 /dc1/rack1
10.93.80.8 host1093808 /dc1/rack1
10.93.80.9 host1093809 /dc1/rack2
~~~

### 查看HADOOP机架信息

~~~
hdfs dfsadmin -printTopology

Rack: /dc1/rack1
10.93.80.7:50010 (host1093807)
10.93.80.8:50010 (host1093808)
Rack: /dc1/rack2
10.93.80.9:50010 (host1093809)
~~~

### 节点间距离计算

有了机架感知，NameNode就可以画出下图所示的datanode网络拓扑图。D1,R1都是交换机，最底层是datanode。
则H1的rackid=/D1/R1/H1，H1的parent是R1，R1的是D1。这些rackid信息可以通过topology.script.file.name配置。
有了这些rackid信息就可以计算出任意两台datanode之间的距离，得到最优的存放策略，优化整个集群的网络带宽均衡以及数据最优分配。

~~~
distance(/D1/R1/H1,/D1/R1/H1)=0 相同的datanode
distance(/D1/R1/H1,/D1/R1/H2)=2 同一rack下的不同datanode
distance(/D1/R1/H1,/D1/R2/H4)=4 同一IDC下的不同datanode
distance(/D1/R1/H1,/D2/R3/H7)=6 不同IDC下的datanode
~~~

