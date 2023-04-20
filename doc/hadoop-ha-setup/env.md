### 修改linux系统参数
* `最大进程数`
* `最大文件打开数`
* `可使用的虚拟内存上限`
~~~
# 查看参数
ulimit -a

# 修改参数 
vim /etc/security/limits.conf

hadoop soft nproc 655360
hadoop hard nproc 655360
hadoop soft nofile 655360
hadoop hard nofile 655360
hadoop soft memlock unlimited
hadoop hard memlock unlimited

# centos7 还需要以下操作
vim /etc/security/limits.d/20-nproc.conf

*    soft  nproc  655360
root soft  nproc  unlimited
~~~

### 设置环境变量
例：
~~~
# 编辑~/.bashrc
vim ~/.bashrc

JAVA_HOME=/data/cloudytrace/jdk1.8.0_181
CLASSPATH=$JAVA_HOME/lib/
PATH=$PATH:$JAVA_HOME/bin

export PATH JAVA_HOME CLASSPATH
export HADOOP_HOME=/data/cloudytrace/hadoop-2.8.5
export PATH=$PATH:$HADOOP_HOME/bin
export HADOOP_CONF_DIR=/data/cloudytrace/hadoop-2.8.5/etc/hadoop
export HADOOP_CLASSPATH=`hadoop classpath`
export JAVA_LIBRARY_PATH=/data/cloudytrace/hadoop-2.8.5/lib/native

# 环境变量立刻生效
source ~/.bashrc
~~~

### 免密登录
masters -> slaves
~~~
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub #{username}@{target_host}
~~~

### 编辑 hadoop 相关变量
~~~
  # 编辑 hadoop-env.sh
  vim hadoop-env.sh
  
  # 添加或覆盖以下内容
  export HADOOP_LOG_DIR=/data/hadoop/logs
  export HADOOP_PID_DIR=#{$HADOOP_HOME}/pids
  export HADOOP_SECURE_DN_PID_DIR=#{$HADOOP_HOME}/pids
~~~