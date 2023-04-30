# HDFS

[官方文档地址](https://hadoop.apache.org/docs/r2.8.5/hadoop-yarn/hadoop-yarn-site/YARN.html)

* [Architecture](yarn-arch.md)
* [Commands Reference](https://hadoop.apache.org/docs/r2.8.5/hadoop-yarn/hadoop-yarn-site/YarnCommands.html)
* [Capacity Scheduler](capacity-scheduler.md)
* [Fair Scheduler](fair-scheduler.md)
* [ResourceManager Restart](resourcemanager-restart.md)
* [ResourceManager HA](resourcemanager-ha.md)
* [Node Labels]
* Web Application Proxy
  <br/>Web应用程序代理是YARN的一部分。默认情况下，它将作为资源管理器(RM)
  的一部分运行，但可以配置为在独立模式下运行。使用代理的原因是为了减少通过YARN进行基于web攻击的可能性。
  但是目前的代理实现没有做任何事情来阻止AM提供到恶意外部站点的链接，也没有做任何事情来防止恶意javascript代码运行。
* Timeline Server
  <br/>在YARN中通过时间轴服务器以通用方式`存储和检索`应用程序的当前和历史信息。它有两个职责:`持久化应用程序特定的信息`
  和`持久化已完成应用程序的一般信息`
* Writing YARN Applications
  编写代码，使用YarnClient向YARN提交application
* [YARN Application Security](https://hadoop.apache.org/docs/r2.8.5/hadoop-yarn/hadoop-yarn-site/YarnApplicationSecurity.html)
* [NodeManager](nodemanager.md)
* Running Applications in Docker Containers
* DockerContainerExecutor
* [Using CGroups](yarn-cgroups.md)
* Secure Containers
* Registry
* [Reservation System](reservation-system.md)

