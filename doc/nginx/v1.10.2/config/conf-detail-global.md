## 全局配置

~~~
# 指定nginx的工作进程的用户及用户组，默认是 nobody nobody
# 通常而言，会给其定义一个用户。如user nginx，那么nginx就有权限来管理其发布目录。这个用户必须存在
user  nobody;

# 指定工作进程的个数，默认是1个。具体可以根据服务器cpu数量进行设置，比如cpu有4个，可以设置为4。
# 一般来说，worker_processes会设置成CPU个数，如果不知道cpu的数量，可以设置为auto。
# nginx会自动判断服务器的cpu个数，并设置相应的进程数。（使用lscpu来查看你的cpu的个数）
worker_processes  auto;

# 为每个进程分配CPU，将八个进程分配给8个CPU，当然也可以写多个，或者将一个进程分配给多个CPU
# 例：worker_cpu_affinity  00000001 00000010 00000100 00001000 00010000 00100000 01000000 10000000;
worker_cpu_affinity  auto;

# 进程的最大打开文件数限制。这样nginx就不会有“too many open files”问题了，最好与ulimit -n的值保持一致。
worker_rlimit_nofile  65535;

# 设置nginx的错误日志路径，并设置相应的输出级别。
# 如果编译时没有指定编译调试模块，那么 info 就是最详细的输出模式了；如果有编译 debug模块，那么 debug 时最为详细的输出模式
# 级别：debug|info|notice|warn|error|crit|alert|emerg
# debug-调试消息。
# info -信息性消息。
# notice -公告。
# warn -警告。
# error -处理请求时出错。
# crit -关键问题。需要立即采取行动。
# alert -警报。必须立即采取行动。
# emerg - 紧急情况。系统处于无法使用的状态
error_log  logs/error.log;
error_log  logs/error.log  notice;
error_log  logs/error.log  info;

# 指定nginx进程pid的文件路径 ，Nginx进程是作为系统守护进程在进行，需要在某个文件中保存当前运行程序的主进程号
# 不指定，默认为 logs/nginx.pid
pid  logs/nginx.pid;
~~~

