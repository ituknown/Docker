# 前言

`Compose` 可以运行与 MacOS,Windows 和 Linux 64 位操作系统。所以你不必考虑操作系统的问题。在安装 Compose 之前，你需要先保证机器已经安装了
`Docker CE-EE Service`，如果你还没有安装 Docker 可以查看 [Docker 安装](../../introduction/install-docker.md) 进行安装。

# 安装

在 Linux 发行版本你可以直接从 [Compose repository release page on GitHub](https://github.com/docker/compose/releases) 下载
Docker Compose 二进制安装包文件。你也可以直接执行如下命令进行下载：

```
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

该命令会将下载的二进制文件存储在 `/usr/local/bin/` 目录下。

> **[info] 小提示**
>
> 直接执行该命令下载的是 `1.23.2` 版本，你也可以指定你想要的版本。

下载完成后可以在 `/usr/local/bin/` 下看到 `docker-compose` 二进制文件：

```
$ ls /usr/local/bin/
docker-compose
```

为 docker-compose 二进制文件赋予可执行权限：

```
$ sudo chmod +x /usr/local/bin/docker-compose
```

> **[danger] 注意**
>
> 如果命令 `docker-compose` 在安装后失败，请仔细检查的路径。你也可以创建指向 `/usr/bin` 或路径中任何其他目录的符号链接，如：
```
$ sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

最后测试是否安装成功（输出版本信息即表示安装成功）：

```
$ docker-compose --version
docker-compose version 1.23.2, build 1110ad01
```

# 升级

随着时间的推移，当前版本可能会慢慢过时。比如你之前安装的是 Compose 1.2或更早之前的版本，就可能存在升级的需求。不过，在升级之后可能需要删除或迁移
现有容器。比如从版本1.3开始，Compose 使用 Docker 标签来跟踪容器，并且需要重新创建容器以添加标签。

如果 Compose 检测到创建的容器没有标签，就无法运行。如果要继续使用现有容器，可以借助 Compose 1.5.x。然后使用以下命令进行迁移：

```
$ docker-compose migrate-to-labels
```

然后想要升级的话重复安装步骤即可，安装需要的版本。

# 卸载 

如果你安装时使用的是 `curl` 命令，卸载时就需要如下命令：

```
$ sudo rm /usr/local/bin/docker-compose
```

如果你安装时使用的是 `pip` 命令，卸载时需要使用如下命令：

```
$ pip uninstall docker-compose
```