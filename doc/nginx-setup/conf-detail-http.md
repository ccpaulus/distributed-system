## http 配置

~~~
http {
    resolver 192.168.131.17 valid=30s;
    resolver_timeout 5s;

    # include是一个引用函数，引入mime.types文件内容
    # mime.types 定义数据类型
    # 如果用户请求lutixia.png，服务器上有lutixia.png这个文件，根据mime.types，这个文件的数据类型是image/png，将Content-Type的值设置为image/png，然后发送给客户端
    include       mime.types;
    
    # 设定默认类型为二进制流，也就是当文件类型未定义时使用这种方式
    # 例如在没有配置PHP环境时，Nginx是不予解析的。此时，用浏览器访问PHP文件就会出现下载窗口。
    default_type  application/octet-stream;

    # 定义日志文件格式，并默认取名为main，可以自定义该名字。也可以通过添加，删除变量来自定义日志文件的格式,main后面的内容定义了日志的格式。
    #log_format  main  '$remote_addr ,- , $remote_user [$time_local] ,"$request" ,'
    #                  '$status $body_bytes_sent ,"$http_referer" ,'
    #                  '"$http_user_agent" ,"$http_x_forwarded_for"';
    #log_format  main  '$remote_addr\t$http_x_forwarded_for\t$remote_user\t$time_iso8601\t$request_method\t"$document_uri"\t"$query_string"\t$server_protocol\t$status\t$body_bytes_sent\t$request_time\t"$http_referer"\t"$http_user_agent"\t$http_Cdn-Src-Ip\t$host\t$hostname\t$server_addr\t+\tV4';
    #log_format  main  '$remote_addr\t$http_x_forwarded_for\t-\t$remote_user\t$time_iso8601\t$request_method\t"$document_uri"\t"$query_string"\t$server_protocol\t$status\t$body_bytes_sent\t$request_time\t"$http_referer"\t"$http_user_agent"\t$http_Cdn-Src-Ip\t$host\t$hostname\t$server_addr\t-\t-\t-\t-\t-\tV5';
    log_format  main '$remote_addr\t$http_x_forwarded_for\t-\t$remote_user\t'
                     '$time_iso8601\t$request_method\t"$document_uri"\t'
                     '"$query_string"\t$server_protocol\t$status\t$body_bytes_sent\t'
                     '$request_time\t"$http_referer"\t"$http_user_agent"\t'
                     '$http_Cdn-Src-Ip\t$host\t$hostname\t$server_addr\t'
                     '$remote_port\t$server_port\t'
                     '"$upstream_addr"\t"$upstream_status"\t"$upstream_response_time"\tV5';

    # 定义访问日志的存放路径，并且通过引用 log_format 所定义的 main 名称引用其输出格式，如果定义了多个日志格式，可以来引用其中一种格式
    access_log  logs/access.log  main;
    server_tokens       off;
    
    # 用于开启高效文件传输模式。直接将数据包封装在内核缓冲区，然后返给客户，将tcp_nopush和tcp_nodelay两个指令设置为on用于防止网络阻塞
    # 默认为off，可以在http块，server块，location块
    sendfile        on;
    #tcp_nopush     on;
    #tcp_nodelay    on;

    # 设置客户端连接保持活动的超时时间。在超过这个时间之后，服务器会关闭该连接，单位：秒
    keepalive_timeout  15;
    concat on;
    
    # 开启目录列表访问，合适下载服务器，默认关闭
    #autoindex on;
    
    # FastCGI相关参数是为了改善网站的性能，减少资源占用，提高访问速度。
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 4 64k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 128k;

    # 开启压缩功能，减少文件传输大小，节省带宽
    gzip  on;
    # 让前端的缓存服务器缓存经过GZIP压缩的页面，例如用Squid缓存经过Nginx压缩的数据
    gzip_vary on;
    # 设置最小的压缩长度，官方设置1K,如果文件大小小于1K，不进行压缩，大于1K就需要压缩
    gzip_min_length  1k;
    # 表示申请4个单位为8K的内存作为压缩结果流缓存，默认值是申请与原始数据大小相同的内存空间来存储gzip压缩结果
    gzip_buffers     4  8k;
    # 指定GZIP压缩比，1 压缩比最小，处理速度最快；9 压缩比最大，传输速度快，但处理最慢，也比较消耗cpu资源
    gzip_comp_level 1;
    # 压缩的类型，设置需要压缩的MIME类型,如果不在设置类型范围内的请求不进行压缩。
    # 图片视频一般是已经压缩了的，再压缩效果也不是很大，所以需要压缩的格式为XML格式
    gzip_types       text/plain application/x-javascript text/css text/htm application/xml application/javascript text/javascript;
    # 设置识别HTTP协议版本，默认是1.1，目前大部分浏览器已经支持GZIP解压，使用默认即可
    gzip_http_version 1.1;
    
    proxy_buffering off;
    proxy_read_timeout 180s;
    proxy_send_timeout 180s;
    
    # 上传文件大小限制
    client_header_buffer_size 32k;
    # 设定请求缓冲
    #large_client_header_buffers 4 64k;
    # 设置允许客户端请求的最大的单个文件字节数
    client_max_body_size 50m;
    # 设置客户端请求头读取超时时间。如果超过这个时间，客户端还没有发送任何数据，Nginx将返回“Request time out（408）”错误
    #client_header_timeout
    # 设置客户端请求主体读取超时时间。如果超过这个时间，客户端还没有发送任何数据，Nginx将返回“Request time out（408）”错误，默认值是60
    #client_body_timeout
    # 指定响应客户端的超时时间。这个超时仅限于两个连接活动之间的时间，如果超过这个时间，客户端没有任何活动，Nginx将会关闭连接
    #send_timeout
    
    # 名称与location proxy_pass 值一致
    # weigth：权重，例：2:1 ... :1
    upstream usname {
        server #{server1}:#{port1} weigth=2;
        server #{server2}:#{port2};
        .
        .
        .
        server #{serverN}:#{portN};
    }
}
~~~


## 日志文件格式参数
* 1.$remote_addr 与 $http_x_forwarded_for 用以记录客户端的ip地址
* 2.$remote_user ：用来记录客户端用户名称 
* 3.$time_local ： 用来记录访问时间与时区
* 4.$request ： 用来记录请求的url与http协议
* 5.$status ： 用来记录请求状态；成功是200
* 6.$body_bytes_s ent ：记录发送给客户端文件主体内容大小
* 7.$http_referer ：用来记录从那个页面链接访问过来的
* 8.$http_user_agent ：记录客户端浏览器的相关信息


## upstream

`upstream`是`Nginx`的`HTTP Upstream`模块，这个模块通过一个简单的调度算法来实现`客户端IP`到`后端服务器`的`负载均衡`。
在上面的设定中，通过`upstream`指令指定了一个负载均衡器的名称`usname`。这个名称可以`任意指定`，在后面需要的地方`直接调用`即可。

### 1、Nginx的负载均衡模块目前支持4种调度算法
其中后两项属于第三方的调度方法。
* 轮询（默认）：每个请求按时间顺序逐一分配到不同的后端服务器，如果后端某台服务器宕机，故障系统被自动剔除，使用户访问不受影响；
* Weight：指定轮询权值，Weight值越大，分配到的访问机率越高，主要用于后端每个服务器性能不均的情况下；
* ip_hash：每个请求按访问IP的hash结果分配，这样来自同一个IP的访客固定访问一个后端服务器，有效解决了动态网页存在的session共享问题；
* fair：比上面两个更加智能的负载均衡算法。此种算法可以依据页面大小和加载时间长短智能地进行负载均衡，也就是根据后端服务器的响应时间来分配请求，响应时间短的优先分配。Nginx本身是不支持fair的，如果需要使用这种调度算法，必须下载Nginx的upstream_fair模块；
* url_hash：按访问url的hash结果来分配请求，使每个url定向到同一个后端服务器，可以进一步提高后端缓存服务器的效率。Nginx本身是不支持url_hash的，如果需要使用这种调度算法，必须安装Nginx 的hash软件包。

### 2、在HTTP Upstream模块中还可以设定每个后端服务器在负载均衡调度中的状态
常用的状态有：
* down：表示当前的`server`暂时不参与负载均衡；
* backup：预留的备份机器。当其他所有的非`backup机器`出现故障或者忙的时候，才会请求`backup机器`，因此这台机器的压力最轻；
* max_fails：允许请求失败的次数，默认为1。当超过最大次数时，返回`proxy_next_upstream`模块定义的错误；
* fail_timeout：在经历了`ax_fails`次失败后，暂停服务的时间。`max_fails`可以和`fail_timeout`一起使用。

例：
~~~
upstream usname {
    ip_hash;
    server #{server1}:#{port1};
    server #{server2}:#{port2};
    .
    .
    .
    server #{serverN}:#{portN};
}
~~~
<font color=red>tips：当负载调度算法为`ip_hash`时，后端服务器在负载均衡调度中的状态不能是`weight`和`backup`</fong>