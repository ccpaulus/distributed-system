## location配置
~~~
# 定义资源路径，默认是直接给一个/根目录，所有资源都从根目录下去找，这个根目录就是发布目录
location / {
    # root是配置服务器的默认网站根目录位置，默认为Nginx安装主目录下的html目录
    root   html;
    # 配置首页文件，必须保证 html/ 下有 index.html 或 index.htm
    index  index.html index.htm;
    
    proxy_pass http://127.0.0.1:88; #反向代理的地址
    proxy_redirect off; #是否开启重定向
    
    #后端的Web服务器可以通过X-Forwarded-For获取用户真实IP
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
    
    #以下是一些反向代理的配置，可选。
    client_max_body_size 10m; #允许客户端请求的最大单文件字节数
    client_body_buffer_size 128k; #缓冲区代理缓冲用户端请求的最大字节数，
    proxy_connect_timeout 90; #nginx跟后端服务器连接超时时间（代理连接超时）
    proxy_send_timeout 90; #后端服务器数据回传时间（代理发送超时）
    proxy_read_timeout 90; #连接成功后，后端服务器响应时间（代理接收超时）
    proxy_buffer_size 4k; #设置代理服务器（Nginx）保存用户头信息的缓冲区大小
    proxy_buffers 4 32k; #proxy_buffers缓冲区，网页平均在32k以下的设置
    proxy_busy_buffers_size 64k; #高负荷下缓冲大小（proxy_buffers*2）
    proxy_temp_file_write_size 64k;  #设定缓存文件夹大小
}

#error_page  404              /404.html;

# redirect server error pages to the static page /50x.html
#
# 定义访问错误返回的页面，凡是状态码是500 502 503 504 都会返回这个页面
error_page   500 502 503 504  /50x.html;
location = /50x.html {
    root   html;
}

#请求的url过滤，正则匹配
location  ~*^.+$ {
   # 请求转向 upstream usname 定义的服务器列表
   proxy_pass  http://usname;
   # 拒绝的ip
   deny 127.0.0.1;
   # 允许的ip
   allow 172.18.5.5;
}

~~~

### url正则表达式
语法：
~~~
location  [ = | ~ | ~* | ^~ ] uri {
  ...
}
~~~
通配符：
* =：用于不含正则表达式的uri前，要求请求字符串与uri严格匹配，如果匹配成功，就停止继续向下搜索并立即处理该请求。
* ~：用于表示uri包含正则表达式，并且区分大小写。
* ~*：用于表示uri包含正则表达式，并且不区分大小写。
* ^~：用于不含正则表达式的uri前，要求Nginx服务器找到标识uri和请求字符串匹配度最高的location后，立即使用此location处理请求，而不再使用location块中的正则uri和请求字符串做匹配。

<font color=red>如果uri包含正则表达式，则必须要有~或者~*标识</font>

### StubStatus模块

#### 1、配置
StubStatus模块能够获取Nginx自上次启动以来的工作状态，此模块非核心模块，需要在Nginx编译安装时手工指定才能使用此功能。以下指令是指定启用获取Nginx工作状态的功能。
~~~
location /NginxStatus {
    stub_status on;
    access_log logs/NginxStatus.log;
    auth_basic "NginxStatus";
    auth_basic_user_file ../htpasswd;
    
    allow 127.0.0.1;
    allow 192.168.138.0/24;
    allow 192.168.241.0/24;
    allow 192.168.242.0/24;
    allow 192.168.119.0/24;
    allow 192.168.207.0/24;
    allow 192.168.90.0/24;
    allow 192.168.224.34;
    deny all;
}
~~~

stub_status设置为“on”表示启用StubStatus的工作状态统计功能。
* access_log 用来指定StubStatus模块的访问日志文件。
* auth_basic是Nginx的一种认证机制。
* auth_basic_user_file用来指定认证的密码文件，由于Nginx的auth_basic认证采用的是与Apache兼容的密码文件，因此需要用Apache的htpasswd命令来生成密码文件，例如要添加一个test用户，可以使用下面方式生成密码文件：
    ~~~
    # 然后输入两次密码后确认之后添加用户成功
    /usr/local/apache/bin/htpasswd -c  /opt/nginx/conf/htpasswd test
    ~~~

#### 2、查看Nginx的运行状态
输入http://#{ip}/NginxStatus，输入创建的用户名和密码就可以看到Nginx的运行状态
~~~
Active connections: 1
server accepts handled requests
34561 35731 354399
Reading: 0 Writing: 3 Waiting: 0
~~~
Active connections表示当前活跃的连接数，第三行的三个数字表示 Nginx当前总共处理了34561个连接， 成功创建35731次握手， 总共处理了354399个请求。
* `Reading`：读取到客户端的Header信息数，表示正处于接收请求状态的连接数
* `Writing`：返回给客户端的Header信息数，表示请求已经接收完成，且正处于处理请求或发送响应的过程中的连接数
* `Waiting`：开启keep-alive的情况下，这个值等于active - (reading + writing)，意思就是Nginx已处理完正在等候下一次请求指令的驻留连接

