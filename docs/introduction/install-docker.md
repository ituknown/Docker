# OS 要求

以下版本的 CentOS 支持 Docker ：

- CentOS 7 (64-bit) or later

请注意，由于 Docker 的局限性，Docker 只能运行在64位的系统中。

# 内核支持

目前的 CentOS 项目，仅发行版本中的内核支持 Docker。如果你打算在非发行版本的内核上运行 Docker ，内核的改动可能会导致出错。

Docker 运行在 CentOS-6.5 或更高的版本的 CentOS 上，需要内核版本是 2.6.32-431 或者更高版本 ，因为这是允许它运行的指定内核补丁版本。

**查看Linux系统版本信息**

```
cat /etc/redhat-release
```

命令示例：

```
[root@localhost ~]# cat /etc/redhat-release 
CentOS Linux release 7.6.1810 (Core)
```


**查看内核版本信息**

```
cat /proc/version
# 或者
uname -a
```

命令示例：

```
[root@localhost ~]# cat /proc/version 
Linux version 3.10.0-957.1.3.el7.x86_64 (mockbuild@kbuilder.bsys.centos.org) (gcc version 4.8.5 20150623 (Red Hat 4.8.5-36) (GCC) ) #1 SMP Thu Nov 29 14:49:43 UTC 2018
[root@localhost ~]# uname -a
Linux localhost.localdomain 3.10.0-957.1.3.el7.x86_64 #1 SMP Thu Nov 29 14:49:43 UTC 2018 x86_64 x86_64 x86_64 GNU/Linux
```

# Docker 版本

Docker 分为 企业版（`docker ee`）和 社区版（`docker ce`）。

Docker Community Edition (`CE`) 非常适合希望开始使用 Docker并尝试基于容器的应用程序的个人开发人员和小型团队。

Docker Enterprise Edition (`EE`)是为企业开发和IT团队而设计的，这些团队构建、发布和运行大规模生产中的业务关键应用程序。

![issue.png](./images/install/issue.png)
