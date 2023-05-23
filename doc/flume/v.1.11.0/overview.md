# Flume

## 概述

Apache Flume是一个分布式的、可靠的、可用的系统，用于有效地收集、聚合和移动来自许多不同来源的大量日志数据到一个集中的数据存储。
Apache Flume的使用不仅限于日志数据聚合。由于数据源是可定制的，Flume可以用来传输大量的事件数据，包括但不限于网络流量数据、社交媒体生成的数据、电子邮件消息和几乎任何可能的数据源。
Apache Flume是Apache软件基金会的一个顶级项目。

## 系统要求

* Java运行时环境：Java 1.8 或 更高版本
* 内存：为 sources、channels 或 sinks 的配置 提供足够的内存
* 磁盘空间：为 channels 或 sinks 的配置 提供足够的磁盘空间
* 目录访问权限：为 agent 使用的目录 提供 读/写 权限

## [架构](architecture.md)

## [安装](setup.md)

## [配置](configuration.md)

## sources/sinks/channels

详见[官网文档](https://flume.apache.org/releases/content/1.11.0/FlumeUserGuide.html#)

## 整合场景

日志收集中一个非常常见的场景是，大量生成日志的客户端将数据发送给附加到存储子系统的几个消费者代理。例如，从数百个web服务器收集的日志发送给十几个写HDFS集群的代理。

![](images/UserGuide_image02.png)

这可以在 Flume 中通过配置一些带有 avro sink 的第一层代理来实现，所有这些 agent 都指向 单个 agent 的 avro source
第二层代理上的 此 source 将接收到的事件合并到 单个 channel 中，该 channel 由 sink 消费到其最终目的地。

