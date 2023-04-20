# Ceph CSI镜像

##官方地址
~~~
k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.4.0
quay.io/cephcsi/cephcsi:v3.6.1
k8s.gcr.io/sig-storage/csi-provisioner:v3.1.0
k8s.gcr.io/sig-storage/csi-resizer:v1.4.0
k8s.gcr.io/sig-storage/csi-snapshotter:v5.0.1
k8s.gcr.io/sig-storage/csi-attacher:v3.4.0
~~~

##`Dev地址`
~~~
xgharborsit01.sncloud.com/sig-storage/csi-node-driver-registrar:v2.4.0
xgharborsit01.sncloud.com/cephcsi/cephcsi:v3.6.1
xgharborsit01.sncloud.com/sig-storage/csi-provisioner:v3.1.0
xgharborsit01.sncloud.com/sig-storage/csi-resizer:v1.4.0
xgharborsit01.sncloud.com/sig-storage/csi-snapshotter:v5.0.1
xgharborsit01.sncloud.com/sig-storage/csi-attacher:v3.4.0
~~~

##`Sit地址`
~~~
harborsit.inner.cnbeankeji.com/sig-storage/csi-node-driver-registrar:v2.4.0
harborsit.inner.cnbeankeji.com/cephcsi/cephcsi:v3.6.1
harborsit.inner.cnbeankeji.com/sig-storage/csi-provisioner:v3.1.0
harborsit.inner.cnbeankeji.com/sig-storage/csi-resizer:v1.4.0
harborsit.inner.cnbeankeji.com/sig-storage/csi-snapshotter:v5.0.1
harborsit.inner.cnbeankeji.com/sig-storage/csi-attacher:v3.4.0
~~~

##`Prd地址`
~~~
harbor.inner.beankeji.com/sig-storage/csi-node-driver-registrar:v2.4.0
harbor.inner.beankeji.com/cephcsi/cephcsi:v3.6.1
harbor.inner.beankeji.com/sig-storage/csi-provisioner:v3.1.0
harbor.inner.beankeji.com/sig-storage/csi-resizer:v1.4.0
harbor.inner.beankeji.com/sig-storage/csi-snapshotter:v5.0.1
harbor.inner.beankeji.com/sig-storage/csi-attacher:v3.4.0
~~~

##注意事项
###1.storageclass
1)`reclaimPolicy: Delete`
~~~
a.动态创建的PV会设置 persistentVolumeReclaimPolicy: Delete
b.删除PVC时会自动删除PV和PV指向的存储
tips:想要保留持久化数据，则不可删除PVC
~~~

2)`reclaimPolicy: Retain`
~~~
a.动态创建的PV会设置 persistentVolumeReclaimPolicy: Retain
b.删除PVC时会不会删除PV
c.删除PV时不会删除存储数据
tips:使用Ceph存储时，删除PV，存储数据将无法被定位和删除
~~~