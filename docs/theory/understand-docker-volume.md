# 前言

想要了解 Docker Volume，首先我们需要知道 Docker 的文件系统是如何工作的。Docker 镜像是由多个文件系统（只读层）叠加而成。当我们启动一个容器的
时候，Docker 会加载只读镜像层并在其上添加一个读写层。如果运行中的容器修改了一个现有已经存在的文件，那该文件将会从读写层下面的只读层复制到读写层，
该文件的只读版本仍然存在，只是已经被读写层中该文件的副本隐藏。当删除 Docker 容器，并通过该镜像重新启动时，之前的更改将会丢失。在Docker中，只读
层及在顶部的读写层的组合称为 **联合文件系统（`Union File System`）**。

为了能够保存（持久化）数据以及共享容器间的数据，Docker 提出了 `volume` 的概念。简单的说，volume 就是目录或者文件，它可以绕过默认的联合文件系
统，而以正常的文件或者目录的形式存在于宿主机上。

我们可以通过两种方式来初始化 volume，这两种方式有些细小而有重要的差别。我们可以在运行容器时使用 `-v` 参数来声明 `volume`：

```bash
$ docker run -it -v /data --name container-test -h CONTAINER /bin/bash
root@CONTAINER: /# ls /data
root@CONTAINER: /#
```

上面的命令会将 `/data` 挂载到容器中，并绕过联合文件系统，我们可以在主机上直接操作该目录。任何在该镜像 `/data` 路径下的文件将会被辅助到 `volume`。
我们可以使用 `docker inspect` 命令找到 volume 在主机上存储的位置：

```bash
$ docker inspect -f {{.Volumes}} container-test
```

你会看到类似的输出：

```
map[/data:/var/lib/docker/vfs/dir/cde167197ccc3e138a14f1a4f...b32cec92e79059437a9]
```

这说明 Docker 把在 `/var/lib/docker` 下的某个目录挂载到了容器内的 `/data` 目录下。让我们从主机上添加文件到该文件夹下：

```bash
$ sudo touch /var/lib/docker/vfs/dir/cde167197ccc3e13814f...b32ce9059437a9/test-file
```

进入容器内可以看到：

```bash
$ root@CONTAINER:/# ls /data
test-file
```

只要将主机的目录挂载到容器的目录上，那改变就会立即生效。我们可以在 Dockerfile 中通过 `VOLUME` 指令来达到相同的目的：

```
FROM debian:wheezy
VOLUME /data
```

但是还有另一件只有 `-v` 参数能够做到而 Dockerfile 是做不到的事情就是在容器上挂载指定的主机目录。例如：

```bash
$ docker run -v /home/adrian/data:/data debian ls /data
```

该命令会将挂载主机的 `/home/adrian/data` 目录到容器内部的 `/data` 目录上。任何在 `/home/adrian/data` 目录的文件都将会出现在容器内。这对
于在主机的容器之间共享文件是非常有帮助的，例如挂载需要编译的源代码。为了保证可移植性（并不是所有的系统的主机目录都是可以用的），挂载主机目录不需要
从 Dockerfile 指定。当使用 `-v` 参数时，镜像目录下的任何文件都不会被复制到 volume 中（volume会复制到镜像目录，镜像不会复制到 volume）。

# 数据共享

如果要授权一个容器能访问另一个容器的 `volume`，我们可以使用 `-volumes-from` 参数来执行 `docker run`。

```bash
$ docker run -it -h NEWCONTAINER --volumes-from container-test debian /bin/bash
root@NEWCONTAINER:/# ls /data
test-file
root@NEWCONTAINER:/#
```

值得注意的是，不管 container-test 是否运行，它都会起作用。只要有容器连接 `volume`，它就不会被删除。

# 数据容器

常见的使用场景是使用纯数据容器来持久化数据库、配置文件或者数据文件等。[官方的文档](https://docs.docker.com/storage/volumes/) 上有详细的
解释。例如：

```bash
$ docker run --name dbdata postgres echo "Data-only container for postgres"
```

该命令将会创建一个已经包含在 Dockerfile 里定义过 Volume 的 postgres 镜像，运行 `echo` 命令退出。当我们运行 `docker ps` 命令时， `echo`
可以帮助我们识别某镜像的用途。我们可以使用哦 `-volumes-from` 命令来识别其它容器的 volume：

```bash
$ docker run -d --volumes-from dbdata --name db1 postgres
```

使用数据容器的两个注意点：

- 不要运行数据容器，这存储是在浪费资源。
- 不要为了数据容器而使用 **最小的镜像**，如 `busybox` 或 `scratch`，只使用数据库镜像本身就可以了。你已经拥有该镜像，所以并不需要占用额外的空间。

# 备份

如果你在用数据容器，那备份是相当容易的：

```bash
$ docker run --rm --volumes-from dbdata -v $(pwd):/backup debian tar cvf /backup/backup.t
```

该示例应该会将 volume 里包含的东西压缩为一个 `tar` 包（官方的 postgres Dockerfile 在 `/var/lib/postgresql/data`）目录下定义了一个 
volume。

# 权限与许可

通常，你需要设置 volume 的权限或者为 volume 初始化一些默认数据或者配置文件。要注意的关键点是：在 Dockerfile 的 `VOLUME` 指令后的任何东西都
不会改变该 volume，比如：

```
FROM debian:wheezy
RUN useradd foo
VOLUME /data
RUN touch /data/x
RUN chown -R foo:foo /data
```

该 Dockerfile 不能按预期那样运行，我们本来希望 `touch` 命令在镜像的文件系统上运行，但是实际上它是在一个临时容器的 volume 上运行。如下所示：

```
FROM debian:wheezy
RUN useradd foo
RUN mkdir /data && touch /data/x
RUN chown -R foo:foo /data
VOLUME /data
```

Dockerfile 可以将镜像中 volume 下的文件挂载到 volume 下，并设置正确的权限。如果你指定 volume 的主机目录将不会出现这种情况。

如果你没有 `RUN` 指令权限，name你就需要在容器启动时使用 `CMD` 或 `ENTRYPOINT` 指令来执行（`CMD` 指令用于指定一个容器启动时需要运行的命令，
与 `RUN` 类似，只是 `RUN` 是镜像在构建时要运行的命令）。

# 删除 Volumes

这个功能可能更加重要，如果你已经使用 `docker rm` 来删除你的容器，那可能有很多孤立的 `volume` 仍然存在并占用着空间。

volume 只有在下列情况下才能被删除：

- 该容器是使用 `docker rm -v <container>` 命令来删除的（`-v` 是必不可少的）。
- `docker run` 中使用了 `--rm` 参数。

即使使用以上命令，也只能删除没有容器连接的 volume。连接到用户指定主机目录的 volume 永远不会被 docker 删除。

除非你已经很小心的，总是像这样来运行容器，否则你将会在 `/var/lib/docker/vfs/dir` 目录下得到一些僵尸文件和目录，并且还不容易说出他们到底代表什么。

- [原文链接](http://dockone.io/article/128)
