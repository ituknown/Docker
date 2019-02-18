# 前言

volume 是保存 Docker 容器生成和使用数据的首选机制。虽然 `bind mounts`（绑定挂载）依赖于主机的目录结构，但是 `volume`（卷）完全由 Docker
管理。使用 volume 由以下优点：

- 相对于 `bind mounts`，`volume` 更容易备份和迁移数据。
- 你可以通过 Docker CLI 命令和 Docker API 进行管理 volumes。
- volume 同时适用于 linux 和 windows。
- 在多容器之间分享数据 volumes 更加安全。
- 使用 volumes 驱动可以实现在远程主机或云上存储卷（`volume`），以及加密卷的内容或添加其他功能。
- 新卷（`volumes`）可以通过容器预先填充内容。

此外，卷（`volumes`）相比于容器的可写层持久化数据更具有优势，因为卷不会增加使用它的容器的大小。并且，卷的内容存储于给定容器的生命周期之外。

![types-of-mounts-volume.png](./_images/types-of-mounts-volume.png)

如果容器生成非持久化状态数据，可以考虑使用 **[tmpfs mount]()** 以避免将数据永久存储在宿主机器中的任何位置，并且通过避免写入容器的可写层来提高
容器的性能。

卷（`volumes`）使用 `rprivate` 绑定传播（propagation），并且卷不可配置绑定传播。

# -v 和 --mount 的选择

一直以来，`-v` 或 `--volume` 选项一直使用于独立容器，`--mount` 选项则是使用于 `swarm` 集群服务中。不过，从 Docker `v17.06` 开始，`--mount` 
同样使用于独立容器。通常，`--mount` 使用起来显得更加明确和详细。他们之间最大的区别在于 `-v` 语法将所有选项组合在一个字段中，而 `--mount` 语法
则将他们分开。

> **[info] 小提示**
>
> 新手应该尝试使用 `--mount` 语法，因为该语法使用起来比 `--volume` 更加简单。

如果需要指定卷（`volumes`）驱动程序选项，那么应该使用 `--mount`。

+ `-v` 或 `--volume`：由三个字段组成，用冒号（`:`）分隔。字段必须按正确的顺序排列，并且每个字段的含义不是很明显。
  - 对于命名卷（`volume`），第一个字段是卷的名称，并且在给定主机上是唯一的。对于匿名卷，该字段可以省略。
  - 第二个字段是文件或目录在容器中安装的路径。
  - 第三个字段是可选字段。用逗号分隔的选项列表，如：`ro`。
  
+ `--mount`：由多个键值对组成，用逗号（`,`）分隔。每个键值由 `<key>=<value>` 元组组成。`--mount` 语法比 `-v` 或 `--volume` 更加详细，
但键的顺序并不重要，并且标识的值更加容易理解。
  - `type` 字段（即 `mount` 的类型，下文省略）可以是 `bind`、`volume` 或 `tmpfs`。本节主题讨论 volume，因此类型始终是 `volume`。
  - `source` 字段。对于显示命名卷，值对应的是 volume 的名称。对于匿名卷，该字段可以省略。另外，`source` 也可以由 `src` 代替。
  - `destination` 字段其值是挂载的容器中的路径（即容器中的路径），该路径是挂载文件或目录的路径。另外，`destination` 也可以由 `dst` 或 `target` 代替。
  - `readonly` 选项。如果存在，则导致绑定挂载以只读的方式安装到容器中。
  - `volume-opt` 选项可以多次指定，它采用由选项名称及其值组成的键值对。
  
> **[success] 从外部CSV解析器中转义值**
>
> 如果你的卷（`volume`）驱动程序接受以逗号（`,`）分隔的列表作为选项，则必须从外部 CSV 解析器中转义该值。要转义 `volume-opt` 选项，则需要使用
> 双引号（`"`）将其包裹起来，并要使用单引号（`'`）包裹住整个 `mount` 参数。
> 例如，`local` 驱动程序接受将挂载选项 `o` 参数以逗号分隔列表。下面示例是转义列表的正确使用方式。
>
```
$ docker service create \
  --mount 'type=volume,src=<volume-name>,dst=<container-path>,volume-driver=local,volume-opt=type=nfs,volume-opt=device=<nfs-server>:<nfs-path>,"volume-opt=o=addr=<nfs-address>,vers=4,soft,timeo=180,bg,tcp,rw"'
  --name myservice \
  <IMAGE-NAME>
```

# -v 和 --mount 之间的行为差异

与绑定挂载（`bind mounts`）相反，卷（`volume`）的所有选项都使用 `--mount` 和 `-v`。

不过，在服务（如：`swarm`集群服务）中使用 `volumes` 时，只有 `--mount` 支持。

# Docker volumes 命令列表

```
$ docker volume --help

Usage:	docker volume COMMAND

Manage volumes

Commands:
  create      Create a volume
  inspect     Display detailed information on one or more volumes
  ls          List volumes
  prune       Remove all unused local volumes
  rm          Remove one or more volumes

Run 'docker volume COMMAND --help' for more information on a command.
```

# 创建、管理 volumes

与绑定挂载（`bind mounts`）不同，你可以创建和管理任何容器范围之外的卷（`volume`）。

- 创建一个 `volume`

```
$ docker volume create my-vol
  my-vol
```

- 列出 `volume`

```
$ docker volume ls
 DRIVER              VOLUME NAME
 local               my-vol
```

- 使用 `inspect` 命令查看 `my-vol` `volume` 信息

```
$ docker volume inspect my-vol
[
    {
        "CreatedAt": "2019-02-04T17:39:34+08:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/my-vol/_data",
        "Name": "my-vol",
        "Options": {},
        "Scope": "local"
    }
]
```

- 删除 `volume`

```
$ docker volume rm my-vol
```

# 容器中使用 volume

如果启动一个尚不存在的卷的容器，Docker 会按需创建。下面示例中展示将一个命名 volume `my-vol2` 挂载进容器的 `/app` 目录。

下面示例中使用 `devtest` 容器， `-v` 和 `--mount` 两个展示结果是相同的。注意，在同一容器中不能同时运行它们，只有删除其中一个才能运行另外一个。

在之前先查看当前机器上的 volumes：

```
$ docker volume ls
 DRIVER              VOLUME NAME
```

<!--sec data-title="使用 --mount 挂载" data-id="section0" data-show=true ces-->

```
$ docker run -d \
  --name devtest \
  --mount source=my-vol2,target=/app \
  nginx:latest
  
 console:
 
 Unable to find image 'nginx:latest' locally
 latest: Pulling from library/nginx
 5e6ec7f28fb7: Pull complete 
 ab804f9bbcbe: Pull complete 
 052b395f16bc: Pull complete 
 Digest: sha256:56bcd35e8433343dbae0484ed5b740843dd8bff9479400990f251c13bbb94763
 Status: Downloaded newer image for nginx:latest
 4d774d44176420027864396ae6cf68a17ad6b326a550bbeb0beee4e38ba610f0
```

现在，再检查一下机器中的 volumes：

```
$ docker volume ls
 DRIVER              VOLUME NAME
 local               my-vol2
```

可以看到，`my-vol2` volume 按需自动创建了。再使用 `inspect` 命令查看该 volume 信息：

```
$ docker volume inspect my-vol2
[
    {
        "CreatedAt": "2019-02-04T18:42:38+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/my-vol2/_data",
        "Name": "my-vol2",
        "Options": null,
        "Scope": "local"
    }
]
```

<!--endsec-->

<!--sec data-title="使用 -v 挂载" data-id="section1" data-show=true ces-->

```
$ docker run -d \
   --name devtest \
   -v my-vol2:/app \
   nginx:latest
```

> 输出结果通 `--mount` 挂载。

<!--endsec-->

现在再使用 `inspect` 命令检查 `devtest` 容器的 `Mounts` 信息：

```
$ docker inspect devtest

...
"Mounts": [
    {
        "Type": "volume",
        "Name": "my-vol2",
        "Source": "/var/lib/docker/volumes/my-vol2/_data",
        "Destination": "/app",
        "Driver": "local",
        "Mode": "z",
        "RW": true,
        "Propagation": ""
    }
]
...
```


可以看到容器中挂载点的 `source` 同 `my-vol2` volume 的 `Mountpoint`。

以上信息展示了 mount 是一个卷，它显示正确的源和目标，并且 mount 是可读写的。

停止容器并移除卷。注意删除卷是一个单独的步骤。

```
$ docker container stop devtest

$ docker container rm devtest

$ docker volume rm myvol2
```

# 服务中使用 volume

当你运行服务并定义一个 volume，每个服务的任务（即容器）都是使用本地卷（`local volume`）。如果使用本地卷驱动程序，则所有容器都不能共享数据。
不过，有些卷驱动程序是支持数据共享的。例如，Docker AWS 和 Docker Azure 都是支持使用 `Cloudstor` 插件的持久化存储。

下面示例展示启动一个 `nginx` 服务，该服务有四个实例，每个实例都使用 `local` volume，volume 的名字是 `my-vol2`。

```
$ docker service create -d \
  --replicas=4 \
  --name devtest-service \
  --mount source=my-vol2,target=/app \
  nginx:latest
  
  7m88h14ly1ocbta20suzrmar3
```

> 注意，在使用服务之前需要使用 `docker swarm init` 命令初始化 `swarm`。

服务成功启动后，可以使用 `docker service ps devtest-service` 命令验证服务是否启动成功：

```
$ docker service ps devtest-service
 ID                  NAME                IMAGE               NODE                    DESIRED STATE       CURRENT STATE            ERROR               PORTS
 kwpvgxntba7i        devtest-service.1   nginx:latest        localhost.localdomain   Running             Running 22 seconds ago                       
 on2ta0awxfdq        devtest-service.2   nginx:latest        localhost.localdomain   Running             Running 22 seconds ago                       
 bvmjo3vku2cy        devtest-service.3   nginx:latest        localhost.localdomain   Running             Running 21 seconds ago                       
 hy8ulezith0h        devtest-service.4   nginx:latest        localhost.localdomain   Running             Running 21 seconds ago 
```

现在再查看下 volume 信息：

```
$ docker volume inspect my-vol2
[
    {
        "CreatedAt": "2019-02-04T22:59:13+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/my-vol2/_data",
        "Name": "my-vol2",
        "Options": null,
        "Scope": "local"
    }
]
```

最后再停止所有任务、移除服务：

```
$ docker service rm devtest-service
```

需要注意，移除服务并不会删除 volume，因为 volume 是在容器的生命周期之外，删除 volume 需要单独的步骤，如下所示：

```
$ docker volume rm <volume-name>
```

> **[info] 小提示**
>
> 在服务中，`docker service create` 命令不支持使用 `-v` 或 `--volume` 选项。想要在服务中挂载 volume，必须使用 `--mount`。

# 使用容器填充 volume

像之前一样，如果你启动一个创建新卷（`volume`）的容器，并且挂载容器中的文件或目录（如之前的 `/app` 目录）。这个目录中的内容会拷贝到新卷中。该容
器挂载并使用的 volume，如果其他容器也使用该 volume，同样也可以访问预先填充的卷内容。

为了说明这点，可以启动一个 `nginx` 容器并创建一个新卷 `nginx-vol`。将该容器中的目录 `/usr/share/nginx/html` 挂载到 volume 中，该目录是
Nginx 默认存储 HTML 内容的目录。

<!--sec data-title="使用 --mount 挂载" data-id="section2" data-show=true ces-->

```
$ docker run -d \
  --name=nginxtest \
  --mount source=nginx-vol,destination=/usr/share/nginx/html \
  nginx:latest
  
6abdcee3be79e012e98eb075346cb1fcd1028c85348d5696c0b3eb375b328d7e
```

```
$ docker volume inspect nginx-vol
[
    {
        "CreatedAt": "2019-02-05T09:35:19+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/nginx-vol/_data",
        "Name": "nginx-vol",
        "Options": null,
        "Scope": "local"
    }
]
```

```
$ ls /var/lib/docker/volumes/nginx-vol/_data
50x.html  index.html
```

可以看到容器中的 Nginx 的 HTML 内容被拷贝到了卷中，实现了 volume 内容预先填充。

<!--endsec-->

<!--sec data-title="使用 -v 挂载" data-id="section3" data-show=true ces-->

```
$ docker run -d \
  --name=nginxtest \
  -v nginx-vol:/usr/share/nginx/html \
  nginx:latest
```

> 结果同 `--mount`

<!--endsec-->

运行完成后，使用以下命令清楚内容和卷。注意：删除卷是一个单独的步骤。

```
$ docker container stop nginxtest

$ docker container rm nginxtest

$ docker volume rm nginx-vol
```

# 使用只读 volume

对于一些部署应用，容器需要写入绑定挂载，以便将更改传播回 Docker 主机。不过，在其他时候，一些容器可能只需要对数据具有读权限即可。之前说过，多个容
器可以同时只挂载到一个 volume。这些容器可以是 **读写** 和 **只读** volume。

下面示例中只是修改了之前的示例，但目录安装为只读卷。对于 `-v`，需要在容器内的挂载点之后将 `ro` 添加到（默认为空）选项列表。如果存在多个选项，需
要使用逗号（`,`）分隔。

<!--sec data-title="使用 --mount 挂载" data-id="section4" data-show=true ces-->

```
$ docker run -d \
  --name=nginxtest \
  --mount source=nginx-vol,destination=/usr/share/nginx/html,readonly \
  nginx:latest
  
201d2add788f000ce7ff78aaa3b76b7dc5348c795fa96e05f076bcbe8a0e6387
```

使用 `docker inspect nginxtest` 进行验证挂载被正确创建。并且，容器对卷的权限为只读权限，可以查看 `Mounts` 栏：

```
$ docker inspect nginxtest

...
"Mounts": [
    {
        "Type": "volume",
        "Name": "nginx-vol",
        "Source": "/var/lib/docker/volumes/nginx-vol/_data",
        "Destination": "/usr/share/nginx/html",
        "Driver": "local",
        "Mode": "z",
        "RW": false,
        "Propagation": ""
    }
]
...
```

<!--endsec-->

<!--sec data-title="使用 -v 挂载" data-id="section5" data-show=true ces-->

```
$ docker run -d \
  --name=nginxtest \
  -v nginx-vol:/usr/share/nginx/html:ro \
  nginx:latest
```

> 同 `--mount`

<!--endsec-->

最后，停止并删除容器以及 volume：

```
$ docker container stop nginxtest

$ docker container rm nginxtest

$ docker volume rm nginx-vol
```

# 多机器之间数据分享

当需要构建一个具有容错性的应用时，你可能需要配置一个具有多个实例的服务，并且这些实例之间能够访问相同的文件。

![volumes-shared-storage.svg](./_images/volumes-shared-storage.svg)

有一下几种方式可以实现如上图所示的应用部署。

- 为应用程序增加逻辑，以将文件存储在云对象存储系统上（如：`Amazon S3`）。
- 使用支持将文件写入诸如 NFS 或 Amazon S3 等外部存储系统的卷（`volumes`）驱动程序的卷。

卷驱动程序允许你从应用程序中抽象底层存储系统。例如，如果你的服务使用 `NFS` 驱动程序的卷，那你可以使用其他驱动程序更新服务。譬如在云存储数据，而无需更改应用程序的逻辑。

# 使用卷驱动程序

当你使用 `docker volume create` 命令创建卷（`volumes`）或者当你运行一个容器并且绑定还未创建的卷时，你可以指定一个卷驱动程序。下面的示例中使用的是 `vieux/sshfs` 卷驱动程序，开始创建爱你一个独立卷，然后当启动容器时创建一个新卷。

## 初始设置

假设你有两个节点，第一个节点是 Docker 主机，可以使用 SSH 连接到第二个节点。

在 Docker 主机上，安装 `vieux/sshfs` 插件：

```
$ docker plugin install --grant-all-permissions vieux/sshfs
```

示例：

```
$ docker plugin install --grant-all-permissions vieux/sshfs

latest: Pulling from vieux/sshfs
52d435ada6a4: Download complete 
Digest: sha256:1d3c3e42c12138da5ef7873b97f7f32cf99fb6edde75fa4f0bcf9ed277855811
Status: Downloaded newer image for vieux/sshfs:latest
Installed plugin vieux/sshfs

$ docker plugin ls

ID                  NAME                 DESCRIPTION               ENABLED
98bfb9819e91        vieux/sshfs:latest   sshFS plugin for Docker   true
```

## 使用卷驱动程序创建卷

该示例需要指定 SSH 密码，不过如果两台主机之间有分享 keys 配置。则可以免密码登录。每个卷驱动程序都有 0 或多个参数配置，每个配置需要使用 `-o` 参数进行指定，命令如下：

```
$ docker volume create --driver vieux/sshfs \
  -o sshcmd=test@node2:/home/test \
  -o password=testpassword \
  sshvolume
```

笔者使用的另一台主机是 `192.168.1.14`，使用 `root` 用户进行登录：

```
$ docker volume create --driver vieux/sshfs \
  -o sshcmd=root@192.168.1.14:/root \
  -o password=MinGRn97 \
  sshvolume

sshvolume
```

命令执行完成后看到创建了一个卷 `sshvolume`。可以在机器上执行卷监测命令查看卷信息：

```
$ docker volume inspect sshvolume
[
    {
        "CreatedAt": "0001-01-01T00:00:00Z",
        "Driver": "vieux/sshfs:latest",
        "Labels": {},
        "Mountpoint": "/mnt/volumes/1124f8042e7a222fb71202f4f1243f13",
        "Name": "sshvolume",
        "Options": {
            "password": "MinGRn97",
            "sshcmd": "root@192.168.1.14:/root"
        },
        "Scope": "local"
    }
]
```

可以看到，在卷的 `Options` 中有你配置的 SSH 登录信息。

## 启动一个使用卷驱动程序创建卷的容器

同样的，你需要使用 SSH 登录到另一台主机，如果主机之间已经共享 `keys` 则不需要设置登录密码了。每个卷驱动程序都有 0 个或多个配置参数。**如果卷驱动程序要求你传递选项，则必须使用 `--mount` 而不是 `-v` 选项。

```
$ docker run -d \
  --name sshfs-container \
  --volume-driver vieux/sshfs \
  --mount src=sshvolume,target=/app,volume-opt=sshcmd=test@node2:/home/test,volume-opt=password=testpassword \
  nginx:latest
```

同样的，笔者使用 `192.168.1.14` 主机的 `root` 用户。所以命令如下：

```
$ docker run -d \
  --name sshfs-container \
  --volume-driver vieux/sshfs \
  --mount src=sshvolume,target=/app,volume-opt=sshcmd=root@192.168.1.14:/root,volume-opt=password=MinGRn97 \
  nginx:latest
```

输出结果如下：

```bash
$  docker run -d \
   --name sshfs-container \
   --volume-driver vieux/sshfs \
   --mount src=sshvolume,target=/app,volume-opt=sshcmd=root@192.168.1.14:/root,volume-opt=password=MinGRn97 \
   nginx:latest

WARN[0000] `--volume-driver` is ignored for volumes specified via `--mount`. Use `--mount type=volume,volume-driver=...` instead. 
5327a73f60b578361f713305984455d6e791d750ffcf624d374aa6ce6346d1b9
```

# 卷数据备份、恢复和迁移

卷对备份、还原和迁移很有用。使用 `--volumes-from` 标志创建一个安装该卷的新容器。

## 备份容器

- 启动一个新容器从 `dbstore` 容器装入卷
- 将本机主机目录挂载为 `/backup`
- 将包含 `dndate` 卷内容的命令传递到 `/backup` 目录中的 `backup.tar` 文件

```bash
$ docker run --rm --volumes-from dbstore -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata
```

当命令执行完成后容器将会停止，并且留下了 `dbdata` 卷的备份。

## 从备份中还原容器

就刚备份的 `dbtate` 而言，我们可以还原数据导到同一个容器或者恢复到另一个容器中。

例如，创一个新容器 `dbstore2`：

```bash
$ docker run -v /dbdata --name dbstore2 ubuntu /bin/bash
```

然后解压缩新容器的数据卷中的备份文件：

```bash
$ docker run --rm --volumes-from dbstore2 -v $(pwd):backup ubuntu bash -c "cd /dbdata && tar xvf /backup/backup.tar --strip 1"
```

你可以使用上述技术使用首选工具自动执行备份，迁移和还原测试。

# 删除卷

当 docker 容器删除时，volume 就会持久化保存，并不会删除。卷有如下两种类型：

- **命名卷** 在容器外有一个特定的源表单，如 `awesome:/bar`。
- **匿名卷** 没有特定的源，所以当容器删除时，指示 Docker Engine 守护程序删除他们。

## 删除匿名卷

使用 `--rm` 参数会自动删除匿名卷。例如，有一个匿名卷 `/foo`，当你的容器删除时，Docker Engine 会自动删除 `/foo` 而不是 `awesome` 卷：

```bash
$ docker run --rm -v /foo -v awesome:bar busybox top
```

## 删除所有卷

要删除所有未使用的卷并释放空间使用如下命令即可：

```bash
$ docker volume prune
```

---

>**说明：** 以上内容翻译至官网文档，笔者还没有进行省层次试验测试。