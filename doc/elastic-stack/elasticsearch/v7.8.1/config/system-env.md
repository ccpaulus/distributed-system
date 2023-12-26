# system-env

vim /etc/security/limits.conf

esadmin soft nproc 655360
esadmin hard nproc 655360
esadmin soft nofile 655360
esadmin hard nofile 655360
esadmin soft memlock unlimited
esadmin hard memlock unlimited


vim /etc/security/limits.d/20-nproc.conf

*          soft    nproc     655360
root       soft    nproc     unlimited


/etc/sysctl.conf

vm.max_map_count=655360
vm.swappiness=0 # memlock 设置为 unlimited，此项可以不配

