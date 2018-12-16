# OS 条件

安装 Docker CE，Centos的系统版本最低要求为 Centos7 或者之后的维护版本。

另外，`centos-extras` 仓库必须开启。该仓库默认是开启的，如果处于关闭状态需要 [开启](https://wiki.centos.org/AdditionalResources/Repositories) 该仓库。

# 卸载 Old Version

Docker 的老版本称为 `docker` 或者 `docker-engine`。如果在系统中已经安装过历史版本需要卸载 ta 以及相关依赖。执行如下命令进行卸载：

```
$ sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
```

命令示例（笔者当前已经安装执行该命令会进行卸载）：

```
[root@localhost ~]# sudo yum remove docker \
>                 docker-client \
>                 docker-client-latest \
>                 docker-common \
>                 docker-latest \
>                 docker-latest-logrotate \
>                 docker-logrotate \
>                 docker-selinux \
>                 docker-engine-selinux \
>                 docker-engine
已加载插件：fastestmirror
参数 docker 没有匹配
参数 docker-client 没有匹配
参数 docker-client-latest 没有匹配
参数 docker-common 没有匹配
参数 docker-latest 没有匹配
参数 docker-latest-logrotate 没有匹配
参数 docker-logrotate 没有匹配
参数 docker-engine 没有匹配
正在解决依赖关系
--> 正在检查事务
---> 软件包 container-selinux.noarch.2.2.74-1.el7 将被 删除
--> 正在处理依赖关系 container-selinux >= 2.9，它被软件包 3:docker-ce-18.09.0-3.el7.x86_64 需要
--> 正在检查事务
---> 软件包 docker-ce.x86_64.3.18.09.0-3.el7 将被 删除
--> 解决依赖关系完成

依赖关系解决

=============================================================================================================================================================================================
 Package                                         架构                                 版本                                             源                                               大小
=============================================================================================================================================================================================
正在删除:
 container-selinux                               noarch                               2:2.74-1.el7                                     @extras                                          37 k
为依赖而移除:
 docker-ce                                       x86_64                               3:18.09.0-3.el7                                  @docker-ce-stable                                81 M

事务概要
=============================================================================================================================================================================================
移除  1 软件包 (+1 依赖软件包)

安装大小：81 M
是否继续？[y/N]：y
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
未将 /usr/bin/dockerd 配置为 dockerd 的备用项
  正在删除    : 3:docker-ce-18.09.0-3.el7.x86_64                                                                                                                                         1/2 
  正在删除    : 2:container-selinux-2.74-1.el7.noarch                                                                                                                                    2/2 
  验证中      : 2:container-selinux-2.74-1.el7.noarch                                                                                                                                    1/2 
  验证中      : 3:docker-ce-18.09.0-3.el7.x86_64                                                                                                                                         2/2 

删除:
  container-selinux.noarch 2:2.74-1.el7                                                                                                                                                      

作为依赖被删除:
  docker-ce.x86_64 3:18.09.0-3.el7                                                                                                                                                           

完毕！
```

docker 的相关镜像（`images`）、容器（`containers`）、卷（`volumes`）、网络（`networks`）全部被存储在 `/var/lib/docker` 文件夹下。

<!--sec data-title="注意" data-id="section0" data-show=true ces-->

执行以上命令虽然将老版本 docker 卸载掉了，但是镜像、容器等数据不会进行清楚。可以进入 `/var/lib` 下可以看到 `docker` 文件夹依然存在，并且该文件夹下还存在相关镜像依赖信息：

```
[root@localhost /]# cd /var/lib/docker
[root@localhost docker]# ls
builder  buildkit  containerd  containers  image  network  overlay2  plugins  runtimes  swarm  tmp  trust  volumes
```

如果想要将这些数据清除掉可以执行如下命令进行清除：

```
$ sudo rm -rf /var/lib/docker
```

同时需要注意，删除数据一时爽。在删除数据之前一定要确定这些确实是脏数据，并且删除后不影响业务运行。否则将会导致不可挽回的损失！

<!--endsec-->



# 安装方式

安装 Docker CE 有多种方式，这里介绍 `yum` 安装方式。

# 安装 Docker Repository

在一台主机上安装 Docker CE 之前需要安装 Docker 仓库 （`Docker repository`），之后不管是更新还是安装都可以直接使用这个仓库。

**设置存储仓库**

安装存储仓库需要安装必要的依赖包。`yum-util` 为 `yum-config-manager` 提供实用工具，并且 `device-mapper-persistent-data` 和 `lvm2` 必须需要 `devicemapper` 进行存储设备驱动。

执行如下命令进行安装：

```
$ sudo yum install -y yum-utils \
                      device-mapper-persistent-data \
                      lvm2
```

命令示例：

```
[root@localhost /]# sudo yum install -y yum-utils \
                                        device-mapper-persistent-data \
                                        lvm2
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.aliyun.com
 * extras: mirrors.aliyun.com
 * updates: mirrors.163.com
base                                                                                                                                                                  | 3.6 kB  00:00:00     
docker-ce-stable                                                                                                                                                      | 3.5 kB  00:00:00     
extras                                                                                                                                                                | 3.4 kB  00:00:00     
updates                                                                                                                                                               | 3.4 kB  00:00:00     
软件包 yum-utils-1.1.31-50.el7.noarch 已安装并且是最新版本
软件包 device-mapper-persistent-data-0.7.3-3.el7.x86_64 已安装并且是最新版本
软件包 7:lvm2-2.02.180-10.el7_6.2.x86_64 已安装并且是最新版本
无须任何处理
```

使用以下命令设置稳定（`stable`）存储库。任何时候总是需要稳定的存储库，即使你想从边缘（`edge`）或者测试（`test`）存储库安装构建。

```
$ sudo yum-config-manager \
       --add-repo \
       https://download.docker.com/linux/centos/docker-ce.repo
```

命令示例：

```
[root@localhost /]# sudo yum-config-manager \
>     --add-repo \
>     https://download.docker.com/linux/centos/docker-ce.repo
已加载插件：fastestmirror
adding repo from: https://download.docker.com/linux/centos/docker-ce.repo
grabbing file https://download.docker.com/linux/centos/docker-ce.repo to /etc/yum.repos.d/docker-ce.repo
repo saved to /etc/yum.repos.d/docker-ce.repo
```

<!--sec data-title="可选操作" data-id="section1" data-show=true ces-->

前面说过，即使你想要使用 `test` 、`edge` 仓库也需要安装 `stable` 仓库。原因是在 `stable` 仓库中已经包含 `test`、`edge`
 仓库，只不过默认是关闭状态，可以执行如下命令进行启用：

 **启用`test`仓库**

```
$ sudo yum-config-manager --enable docker-ce-test
```

 **启用`edge`仓库**

```
$ sudo yum-config-manager --enable docker-ce-edge
```

如果你想要再次关闭 `edge` 或者 `test` 仓库，可以使用 `yum-config-manager` 和 `--disable` 组合命令。想要再次开启则使用 `--enable` 命令。下面是关闭 `edge` 仓库示例命令：

```
$ sudo yum-config-manager --disable docker-ce-edge
```

**注意：** Docker 从 `17.06` 版本开始， `stable` 也被推送至 `edge`和 `test` 仓库。

<!--endsec-->

# 开始安装 Docker CE

**安装最新版本：**

```
$ sudo yum install docker-ce
```

这种方式总是安装最新版本，如果想安装指定版本使用下面安装方式：

**安装指定版本：**

安装指定版本首先需要查找版本列表，指定其中一个进行安装。使用下面命令进行查找版本列表：

```
$ yum list docker-ce --showduplicates | sort -r
```

使用这个命令可以将 `stable` 版本列表列出并且将版本按从高到低进行展示。注意：只会展示部分版本信息。

使用示例：

```
[root@localhost /]# yum list docker-ce --showduplicates | sort -r
已加载插件：fastestmirror
可安装的软件包
 * updates: mirrors.163.com
Loading mirror speeds from cached hostfile
 * extras: mirrors.aliyun.com
docker-ce.x86_64            3:18.09.0-3.el7                     docker-ce-stable
docker-ce.x86_64            18.06.1.ce-3.el7                    docker-ce-stable
docker-ce.x86_64            18.06.0.ce-3.el7                    docker-ce-stable
docker-ce.x86_64            18.03.1.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            18.03.0.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.12.1.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.12.0.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.09.1.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.09.0.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.06.2.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.06.1.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.06.0.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.03.3.ce-1.el7                    docker-ce-stable
docker-ce.x86_64            17.03.2.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.03.1.ce-1.el7.centos             docker-ce-stable
docker-ce.x86_64            17.03.0.ce-1.el7.centos             docker-ce-stable
 * base: mirrors.aliyun.com
```

可以看到列出部分版本，并且标识在后都进行标注版本的状态 `docker-ce-stable`。安装时只需要使用如下命令指定版本号即可：

```
$ sudo yum install docker-ce-<VERSION>
```

比如安装如下版本：

```
docker-ce.x86_64            18.03.0.ce-1.el7.centos             docker-ce-stable
```

输入命令如下命令即可安装：

```
$ sudo yum install docker-ce-18.03.0.ce-1
```

如笔者直接安装最新版本示例：

```
[root@localhost /]# sudo yum install docker-ce
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.aliyun.com
 * extras: mirrors.aliyun.com
 * updates: mirrors.163.com
正在解决依赖关系
--> 正在检查事务
---> 软件包 docker-ce.x86_64.3.18.09.0-3.el7 将被 安装
--> 正在处理依赖关系 container-selinux >= 2.9，它被软件包 3:docker-ce-18.09.0-3.el7.x86_64 需要
--> 正在检查事务
---> 软件包 container-selinux.noarch.2.2.74-1.el7 将被 安装
--> 解决依赖关系完成

依赖关系解决

=============================================================================================================================================================================================
 Package                                          架构                                  版本                                           源                                               大小
=============================================================================================================================================================================================
正在安装:
 docker-ce                                        x86_64                                3:18.09.0-3.el7                                docker-ce-stable                                 19 M
为依赖而安装:
 container-selinux                                noarch                                2:2.74-1.el7                                   extras                                           38 k

事务概要
=============================================================================================================================================================================================
安装  1 软件包 (+1 依赖软件包)

总下载量：19 M
安装大小：81 M
Is this ok [y/d/N]: y'
Is this ok [y/d/N]: y
Downloading packages:
(1/2): container-selinux-2.74-1.el7.noarch.rpm                                                                                                                        |  38 kB  00:00:00     
(2/2): docker-ce-18.09.0-3.el7.x86_64.rpm                                                                                                                             |  19 MB  00:00:04     
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
总计                                                                                                                                                         4.0 MB/s |  19 MB  00:00:04     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  正在安装    : 2:container-selinux-2.74-1.el7.noarch                                                                                                                                    1/2 
  正在安装    : 3:docker-ce-18.09.0-3.el7.x86_64                                                                                                                                         2/2 
  验证中      : 2:container-selinux-2.74-1.el7.noarch                                                                                                                                    1/2 
  验证中      : 3:docker-ce-18.09.0-3.el7.x86_64                                                                                                                                         2/2 

已安装:
  docker-ce.x86_64 3:18.09.0-3.el7                                                                                                                                                           

作为依赖被安装:
  container-selinux.noarch 2:2.74-1.el7                                                                                                                                                      

完毕！
```

到现在为止 docker-ce 已经安装完成。注意，这里只是安装完成，并没有运行！

# 运行 Docker CE

输入如下命令进行启用 Docker：

```
$ sudo systemctl start docker
```

可以输入命令如下命令查看 docker 进程：

```
$ ps -aux | grep docker
```

# 验证 Docker

虽然 Docker CE 已经安装并运行，但是我们需要进行验证 Docker 是否进行正确的安装，这里可以运行 `hello-world` 镜像进行验证。

```
$ sudo docker run hello-world
```

这个命令会下载一个测试镜像并且运行起来成为一个容器，当它运行后会输出信息并且退出。

运行示例：

```
[root@localhost /]# sudo docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

现在 Docker 才算真正的安装运行完成。运行 docker 需要使用 `sudo` 超级管理员身份运行。可以点击 [**传送门**](https://docs.docker.com/install/linux/linux-postinstall/) 进行设置允许非特权用户进行运行 Docker 命令。

# 更新 Docker CE

如果需要更新 Docker CE 需要进行下载一个新的安装包文件，并重复之前的步骤。然后使用 `yum -y upgrade` 不是使用 `yum -y install` 命令进行指定一个新的包文件。

# 卸载 Docker CE

如果卸载 Docker CE 直接使用如下命令卸载即可：

```
$ sudo yum remove docker-ce
```

需要注意的是，卸载不会删除已存在的镜像、容器等其他数据。这些包数据都存储在 `/var/lib/docker` 目录下，可以直接使用删除命令进行清除：

```
$ sudo rm -rf /var/lib/docker
```
