# Ceph安装-前置事项

## 1.用户
_tips_:可直接使用 **root** 用户，但不要使用**ceph**作为用户名，**ceph**是ceph守护进程的保留用户名，已存在**ceph**用户的话需先删除
### 创建用户
~~~
ssh user@ceph-server
sudo useradd -d /home/{username} -m {username}
sudo passwd {username}
~~~
### 用户赋权
~~~
echo "{username} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/{username}
sudo chmod 0440 /etc/sudoers.d/{username}
~~~

## 2.设置hostname
~~~
hostnamectl set-hostname {node_hostname}
~~~

## 3.配置SSH免密
admin节点到集群节点，单向免密
~~~
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub root@{node_hostname}
~~~

## 4.关闭防火墙
~~~
systemctl stop firewalld
systemctl disable firewalld
~~~

## 5.配置yum阿里源
`wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo`
\
`vim /etc/yum.repos.d/CentOS-Base.repo`
~~~
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/os/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#released updates 
[updates]
name=CentOS-$releasever - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/updates/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/extras/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/centosplus/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/centosplus/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#contrib - packages by Centos Users
[contrib]
name=CentOS-$releasever - Contrib - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/contrib/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/contrib/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/contrib/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
~~~
`vim /etc/yum.repos.d/ceph.repo`
~~~
[Ceph-SRPMS]
name=Ceph SRPMS packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-15.2.16/el7/SRPMS/
enabled=1
gpgcheck=0
type=rpm-md
[Ceph-aarch64]
name=Ceph aarch64 packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-15.2.16/el7/aarch64/
enabled=1
gpgcheck=0
type=rpm-md
[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-15.2.16/el7/noarch/
enabled=1
gpgcheck=0
type=rpm-md
[Ceph-x86_64]
name=Ceph x86_64 packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-15.2.16/el7/x86_64/
enabled=1
gpgcheck=0
~~~

~~~
yum clean all
yum repolist
~~~

## 6.时钟同步
~~~
#安装ntp
yum -y install ntp

#验证时钟同步服务器
ntpdate 10.237.77.57

#配置/etc/ntp.conf
server 10.237.77.57 iburst

#停止其他时钟同步，防止干扰
systemctl list-unit-files | grep chronyd
systemctl disable chronyd.service
systemctl disable ntpdate.service

#配置启动服务
systemctl enable ntpd.service
systemctl start ntpd.service
ntpstat
~~~

### 7.安装ceph-deploy（admin节点）
~~~
yum -y install ceph-deploy
~~~

### 8.kernel 升级（需要时处理）
~~~
#0.注意保留一个可用的老内核，以作升级回退

#1.修改yum源
vim /etc/yum.repos.d/kernel.repo
[kernel418]
name=kernel418
baseurl=http://192.168.86.5/centos73/kernel-update
enabled=1
gpgcheck=0

#2.升级报错冲突，可能是因为被动引入了 xorg-x11-drv-vmmouse ， 需要执行  yum remove  xorg-x11-drv-vmmouse 卸掉包，解决冲突，是图形桌面相关的包，评估后台系统不需要
yum remove  xorg-x11-drv-vmmouse

#3.更新内核
yum update kernel -y

#4.确认是否已更新为新内核版本，如果不是手动改成新版本内核
cat /boot/grub2/grubenv
#手动修改方法，将menuentry后 ' '内的内容copy到grubenv中
cat /boot/grub2/grub.cfg |grep menuentry

#5.修改yum配置，并重启
vim /etc/yum.conf
#修改installonly_limit=2
reboot
~~~