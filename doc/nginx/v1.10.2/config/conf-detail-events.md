## events配置

~~~
events {
    # 用来指定nginx的工作模式（事件驱动），通常选择epoll，除了epoll，还有 select|poll|kqueue|epoll|resig|/dev/poll|eventport
    use  epoll;
    
    # 设置网路连接序列化，防止【惊群现象】发生，默认为on
    # 惊群现象：一个网路连接到来，多个睡眠的进程被同事叫醒，但只有一个进程能获得链接，这样会影响系统性能
    accept_mutex  off;
    
    # 设置是否允许同时接受多个网络连接(connections)，只能在events模块设置，Nginx服务器的每个工作进程可以同时接受多个新的网络连接
    # 此指令默认为关闭，即默认为一个工作进程只能一次接受一个新的网络连接，打开后几个同时接受多个
    multi_accept  on;
    
    # 定义每个工作进程的最大连接数，默认是1024
    worker_connections  10240;
}
~~~

