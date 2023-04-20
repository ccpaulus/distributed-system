# nginx安装&配置

Nginx（“engine x”）是一款高性能的http服务器，反向代理服务器，电子邮件（IMAP/POP3）代理服务器。

Nginx 可以作为静态页面的Web服务器，同时还支持CGI协议的动态语言，比如Perl、PHP等。但是不支持Java。Java程序只能通过与Tomcat配合完成。

Nginx 能支持5万高并发链接，免费开源，cpu、内存等资源消耗非常低，运行稳定。

Nginx 是一个主和几个工作进程；工作进程在非特权用户下运行。Nginx可以灵活配置， 重新配置和升级可执行文件，而不会中断客户端服务。

### 功能
* 基本的 HTTP 服务器功能
* 其他 HTTP 服务器功能（虚拟服务器、管道连接、限流等等）
* 邮件代理服务器功能
* TCP/UDP 代理服务器功能 （1.9以后）

### 特性
Nginx使用可扩展的事件驱动架构，而不是更传统的过程驱动架构。这需要更低的内存占用，并且当并发连接扩大时，使内存使用更可预测。

Nginx开发的目标是实现 10 倍以上的性能，优化服务器资源的使用，同时也能够扩展和支持网站的动态增长。 因此，Nginx成为最知名的模块化，事件驱动，异步，单线程 的 非阻塞架构 Web 服务器和 Web 代理之一。

Nginx 是一个高性能的 Web 和反向代理（Reverse Proxy）服务器, 它具有很多非常优越的特性：
* 作为 Web 服务器：相比 Apache，Nginx 使用更少的资源，支持更多的并发连接，体现更高的效率，这点使 Nginx 尤其受到虚拟主机提供商的欢迎。
* 作为负载均衡（Load Balance）服务器：Nginx 既可以在内部直接支持 Rails 和 PHP，也可以支持作为 HTTP 代理服务器 对外进行服务。Nginx 用 C 编写, 不论是系统资源开销还是 CPU 使用效率都比 Perlbal 要好的多。
* 作为邮件代理服务器：Nginx 同时也是一个非常优秀的邮件代理服务器，能够在 不间断服务的情况下进行软件版本的升级。


## 1.安装

### 安装依赖库
* 安装gcc环境，nginx是c语言开发的，因此安装nginx需要安装gcc环境
* 安装pcre库，nginx的http模块需要pcre来解析正则表达式，而pcre-devel是pcre开发的一个二次开发库
* 安装zlib库，zlib库提供了很多种压缩和解压缩的方式，nginx使用zlib对http包的内容进行gzip
* 安装openSSL，nginx不仅支持http协议，还支持https协议（在ssl协议上传输http），openSSL是一个强大的安全套接字层密码库，囊括主要的密码算法、常用的密钥和证书封装管理功能以及SSL协议，并提供丰富的应用程序供测试或其他目的使用
~~~
yun install gcc-c++
yum install -y pcre pcre-devel
yum install -y zlib zlib-devel
yum install -y openssl openssl-devel
~~~

### 下载安装 nginx
~~~
# 下载安装包
wget http://nginx.org/download/nginx-1.0.14.tar.gz
# 解压
tar zxvf nginx-1.0.14.tar.gz.
# 进入安装包目录
cd nginx-1.0.14
# configure命令创建一个makefile文件
# –with-http_stub_status_module 可以用来启用 Nginx 的 NginxStatus 功能，以监控 Nginx 的运行状态。想要了解更多的模块的情况可以通过 ./configure –help 选项查看
/configure --with-http_stub_status_module --prefix=/usr/local/nginx
# 编译
make
# 安装
make install
~~~

### 启动
~~~
cd /usr/local/nginx/sbin
./nginx
~~~

### 关闭
~~~
# a)快速关闭服务，不管有没有正在处理的请求，都马上关闭nginx
./nginx -s stop

# b)优雅关闭服务，指的是在关闭前，需要把已经接受的连接请求处理完
./nginx -s quit
~~~

### 测试配置文件
~~~
./nginx -t
~~~

### 重启加载配置文件
~~~
# master 不变，worker 重启
./nginx -s reload
~~~

### 开放Nginx防火墙
~~~
/sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
/etc/rc.d/init.d/iptables save
~~~


## 2.[nginx配置文件的结构](conf-structure.md)

## 3.[nginx配置文件解析](conf-detail.md)

## 4.[nginx静态资源](static-resources.md)

## 5.[架构&原理](nginx-architecture.md)

## 6.[nginx HA](nginx-ha.md)

