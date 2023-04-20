## server配置

~~~
# 定义虚拟主机，不同的 server 端口不能一样
server {
    # 设置监听端口，默认为80端口
    listen       80;
    
    # 网站域名，多个域名通过逗号隔开，默认是localhost
    server_name  localhost;

    # 设置网页的默认编码格式，一般设置为charset utf-8
    charset utf-8;

    # 指定该虚拟主机的独立访问日志，会覆盖前面的全局配置日志文件。如果有有多个虚拟主机，那么每个虚拟主机都需要配置自己的access_log
    access_log  /opt/rsync_log/access_http.log  main;
}
~~~

