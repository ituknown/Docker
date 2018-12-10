# 常见问题

## Is the docker daemon running?

```
[root@localhost ~]# docker images
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
[root@localhost ~]# sudo systemctl start docker
[root@localhost ~]# docker images
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
ifkeeper/jvm8          v1.0.0              9ef7f38f2bf1        18 hours ago        583MB
jvm8                   v1.0.0              9ef7f38f2bf1        18 hours ago        583MB
ifkeeper/centos-jvm8   v1.0.0              e15334134272        37 hours ago        583MB
centos                 latest              1e1148e4cc2c        4 days ago          202MB
openjdk                latest              8e7eacedab93        5 days ago          986MB
```
