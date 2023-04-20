# Redis Sentinel K8S存储改造

##修改所有statefulset
将原有 `storageClassName: local-storage` 改为 `storageClassName: csi-rbd-sc`
~~~
  volumeClaimTemplates:
    - metadata:
        name: sentinel-alpha
      spec:
        accessModes: [ "ReadWriteOnce" ]
        storageClassName: local-storage
        resources:
          requests:
            storage: 75Gi
~~~

##删除原有PV
~~~
1、根据statefulset name找到PVC name
2、根据PVC name找到绑定的PV资源，并将其删除
3、删除PVC资源
~~~