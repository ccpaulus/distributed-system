## nginx配置文件的结构

~~~
...              #全局块
 
events {         #events块
   ...
}
 
http      #http块
{
    ...   #http全局块
    
    server        #server块
    {
        ...       #server全局块
        location [PATTERN]   #location块
        {
            ...
        }
        location [PATTERN]
        {
            ...
        }
    }
    server
    {
      ...
    }
    
    ...     #http全局块
}
~~~

一个`http`可以存在多个`server`，一个`server`里面可以包含多个`location`。一般只配置一个`http`，这样就一个实例

* `main`全局块：配置影响`nginx`全局的指令。一般有运行`nginx`服务器的用户组，`nginx`进程`pid`存放路径，日志存放路径，配置文件引入，允许生成`worker process`数等。

* `events`块：配置影响`nginx`服务器或与用户的网络连接。有每个进程的最大连接数，选取哪种事件驱动模型处理连接请求，是否允许同时接受多个网路连接，开启多个网络连接序列化等。

* `http`块：可以嵌套多个`server`，配置代理，缓存，日志定义等绝大多数功能和第三方模块的配置。如文件引入，`mime-type`定义，日志自定义，是否使用`sendfile`传输文件，连接超时时间，单连接请求数等。

* `server`块：配置虚拟主机的相关参数，一个`http`中可以有多个`server`。

* `location`块：配置请求的路由，以及各种页面的处理情况。
