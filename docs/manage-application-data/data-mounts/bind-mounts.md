# 前言

自 Docker 早起，绑定挂载（`bind mounts`）就已经存在。与 [volumes](./use-volumes.md) 相比，`bind mount` 具有一定的限制，并且在安全性上
无法得到保障。当你使用绑定挂载（`bind mounts`）时，主机上的一个文件或者目录就会被挂载到容器中。文件可以是主机上的相对路径或完整路径。相反，使用
volumes 时，Docker 会在自动主机上的 Docker 存储目录创建一个新目录，Docker 会管理该目录的内容而无需自己维护。

`bind mounts` 的文件或目录不需要已存在于 Docker 主机上，在使用绑定挂载（`bind mounts`）时会按需创建文件或目录。绑定挂载（`bind mounts`）
非常高效，但它依赖于主机上特定的目录结构的主机文件系统。如果在开发新的 Docker 应用程序时，应该优先考虑使用命名卷（`named volumes`），因为 `bind mount`
无法直接使用 Docker CLI 命令进行直接管理。可以通过下面这张图了解 `bind mount` 相比较 `volume` 和 `tmpfs mount` 之间数据存储位置的不同。

![types-of-mounts-bind.png](./_images/types-of-mounts-bind.png)

# --volume 和 --mount

从 docker 诞生之初，`-v` 或 `--volume` 选项一直使用于独立容器，`--mount` 选项则是使用于 `swarm` 集群服务中。不过，从 Docker `v17.06` 开始，`--mount` 
同样适用于独立容器。与 `--volume` 相比较，`--mount` 语法更清晰直观。它们之间最大的区别在于 `--volume` 语法是将所有选项组合在一个字段中，而 `--mount` 语法
则将他们分开。

> **[info] 小提示**
>
> 新手应该尝试使用 `--mount` 语法，因为该语法使用起来比 `--volume` 更加简单。

下面具体说下在使用 `bind mount` 时 `--volume` 和 `--mount` 语法的区别。

+ `-v` 或 `--volume`：语法由三个字段组成，用冒号（`:`）分隔。字段之间必须按正确的顺序排列。
  - 对于绑定挂载（`bind mounts`），第一个字段是宿主机器上挂载的文件或目录的路径（可以是相对路径或绝对路径）。
  - 第二个字段是挂载到容器中的文件或目录的路径（即在容器中的路径）。
  - 第三个字段是可选字段。用逗号分隔的选项列表，如：`ro`、`consistent`、`delegated`、`z` 和 `Z`，后续作说明。
  
+ `--mount`：语法由多个键值对组成，多个键值对之间用逗号（`,`）分隔。每个键值由 `<key>=<value>` 元组组成。与 `--volume` 语法不同，`--mount`
对键值对的顺序不做要求。
  - `type` 字段（即 `mount` 的类型）可以是 `bind`、`volume` 或 `tmpfs`。本节主要介绍 `bind mount`，因此类型始终是 `bind`。
  - `source` 字段。对于绑定挂载（`bind mounts`），这个字段值是 Docker 服务主机上的文件或目录路径，也可以使用 `src` 代替 `source`。
  - `destination` 字段其值是挂载到容器中的路径（即容器内部的路径）。另外，`destination` 也可以由 `dst` 或 `target` 代替。
  - `readonly` 选项。如果指定，则绑定挂载以只读的方式安装到容器中。
  - `bind-propagation` 字段是可选的。主要作用是绑定传播（`bind propagation`），可以是 `rprivate`、`private`、`rshared`、`shared`、`rslave`、`slave` 中的其中一个。
  - `consistency` 选项，此设置仅适用于 Docker Desktop for Mac，在所有其他平台上均被忽略。可以是 `consistent`、`delegated` 或 `cached`。
  - `--mount` 不支持 `z` 或 `Z` 来修改 `selinux` 标签。
  
# --volume 和 --mount 的行为差异

因为 `-v` 和 `--volume` 选项长期以来一直是 Docker 的一部分，所以他们的行为无法改变。这意味着 `-v` 和 `--mount` 之间存在一种不同的行为。

如果你使用 `-v` 或 `--volume` 进行绑定宿主机上不存在的文件或目录，`-v` 会自动创建一个端点。**它始终作为目录进行创建。**

如果你使用 `--mount` 进行绑定宿主机上不存在的文件或目录，Docker **不会自动的创建**，但是会输出错误信息。

# 在容器中使用 bind mount

这里以构建 Maven 应用进行说明。假设你要挂载的 `source` 是 maven 应用（如 `mvn clean package`），你希望每次在构建时都能直接应用于 Docker 
容器。如 `source` 路径为当前目录下载 `target` 目录（Maven 打包后生成的目录），要挂载的目录是容器的 `/app` 路径。这样，当你每次进行重新构建时
都能直接应用于容器。

使用如下命令将 `target/` 目录绑定到 `/app/` 目录，从 `source` 目录运行该命令。`$(pwd)` 是 Linux 上的子命令，表示当前工作目录。

<!--sec data-title="使用 --mount 语法" data-id="section0" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  nginx:latest
```
<!--endsec-->

<!--sec data-title="使用 --volume 语法" data-id="section1" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app \
  nginx:latest
```
<!--endsec-->

使用 `inspect` 命令进行检查 `devtest` 容器。查看 `Mount` 信息：

```
$ docker inspect devtest

...
"Mounts": [
    {
        "Type": "bind",
        "Source": "/home/MinGRn/source/target",
        "Target": "/app",
        "Mode": "",
        "RW": true,
         "Propagation": "rprivate"
    }
]
...
```

从输出的信息中可以看到，使用的是 `bind` 类型挂载，并且显示了正确的源和挂载点。该挂载具有 `read-write` 权限，传播级别是 `rprite`。

最后停止并删除容器：

```$
$ docker container stop devtest
$ docker container rm devtest
```

# 在容器中挂载一个非空目录

如果你使用 `bind mount` 挂载到容器中的目录时一个非空的目录，则 `bind mount` 会隐藏目录中现有的内容。这有一点好处，比如你想要在不构建新镜像的
基础上测试一个新版本的应用程序。

用主机上的 `/tmp/` 目录替换容器的 `/usr/` 目录的内容，这个例子设计得极端。在大多数情况下，这会导致容器无法运行。

<!--sec data-title="使用 --mount 语法" data-id="section2" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name broken-container \
  --mount type=bind,source/tmp,target=/usr \
  nginx:latest
  
688d4fe924fb60a48d256257526cc0172749ba0fd2c68ac721a41e4e59e9fc0f
docker: Error response from daemon: OCI runtime create failed: container_linux.go:344: starting container process caused "exec: \"nginx\": executable file not found in $PATH": unknown.
```
<!--endsec-->

<!--sec data-title="使用 --volume 语法" data-id="section3" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name broken-container \
  -v /tmp:/usr \
  nginx:latest

docker: Error response from daemon: oci runtime error: container_linux.go:262:
starting container process caused "exec: \"nginx\": executable file not found in $PATH".
```
<!--endsec-->

从上面的栗子可以看到，容器虽然被创建了，但是无法运行。最后删除它：

```
$ docker container rm broken-container
```

# 使用只读挂载

大多数情况下，部署一个应用程序容器需要在绑定挂载中进行写文件，所以更改会传播到 Docker 宿主机。在有些时候，容器可能只需要读访问权限即可。

此示例修改上面的一个，但是通过在容器中的挂载点之后将 `ro` 添加到（默认为空）选项列表，将目录挂载为只读绑定挂载。如果存在多个选项，请用逗号分隔。

<!--sec data-title="使用 --mount 语法" data-id="section4" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app,readonly \
  nginx:latest
```
<!--endsec-->

<!--sec data-title="使用 --volume 语法" data-id="section5" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app:ro \
  nginx:latest
```
<!--endsec-->

使用 `inspect` 命令进行检查 `devtest` 容器。查看 `Mount` 信息：

```
$ docker inspect devtest

...
"Mounts": [
    {
        "Type": "bind",
        "Source": "/home/MinGRn/source/target",
        "Target": "/app",
        "Mode": "",
        "RW": false,
         "Propagation": "rprivate"
    }
]
...
```

从输出信息中可以看到，`RW` 为只读权限。最后停止并删除容器：

```
$ docker container stop devtest

$ docker container rm devtest
```

# 配置绑定传播机制

`bind mounts` 和 `volumes` 默认使用的绑定传播（`bind propagation`）机制是 `rprivate`。在 volume 是无法配置该机制的，不过 `bind mount`
中可以进行配置。注意：这是一个高级主题，在大多数情况下用户是不需要配置的，使用默认的即可。

**绑定传播是指在给定的绑定装载或命名卷中创建的装载是否可以传播到该装载的副本。** 考虑一个安装点 `/mnt`，它也安装在 `/tmp` 上面。传播机制控制
`/tmp/a` 是否也可以使用挂载 `/mnt/a`。每个传播设置都有一个递归对位。在递归的情况下，要考虑 `/tmp/a` 是否也挂载到 `/foo`。传播设置控制
`/mnt/a` 或 `/tmp/a` 是否存在。

|**传播设置**|**描述**|
|:----:|:----|
|`shared` | 原始挂载的子挂载将暴露给副本挂载，副本挂载的副本挂载也会传播到原始挂载|
|`rshared`| 类似于 `shared`，不过是单方向传播。如果原始挂载程序公开子挂载，则副本挂载程序可以看到它。但是，如果副本挂载公开子挂载，则原始挂载无法看到它。|
|`private`| 挂载是私有的，子挂载不会暴露给副本挂载。同样，副本挂载也不会暴露给原始挂载。|
|`rprivate`|默认。与private相同，意味着原始或副本装入点中任何位置的装载点都不会沿任一方向传播 |
|`slave` | 类似于 `shared`，但只在一个方向上。如果原始安装程序公开子安装，则副本安装程序可以看到它。但是，如果副本装置公开了子装载，则原始装载无法看到它。|
|`ralave`|与 `slave` 相同，但传播也延伸到嵌套在任何原始或副本装入点内的装入点。|

在可以在挂载点上设置绑定传播之前，主机文件系统需要已经支持绑定传播。有关更多的绑定传播信息，见 [共享子树的Linux内核文档](https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt)。

一下示例将 `target/` 目录挂载到容器中两次，第二次安装设置 `ro` 选项和 `rslave` 绑定传播选项。

<!--sec data-title="使用 --mount 语法" data-id="section6" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  --mount type=bind,source="$(pwd)"/target,target=/app2,readonly,bind-propagation=rslave \
  nginx:latest
```
<!--endsec-->

<!--sec data-title="使用 --volume 语法" data-id="section7" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app \
  -v "$(pwd)"/target:/app2:ro,rslave \
  nginx:latest
```
<!--endsec-->

现在，如果你创建 `/app/foo`，`/app2/foo` 也会存在。

# 总结

虽然 `bind mount` 也同 volume 一样可以将 docker 容器中的数据进行持久化。但是，在实现该功能时你应该尽可能的使用 volume。因为 `bind mount`
需要进行指定挂载的宿主机器的文件或目录，并且该文件或目录是任意的，即使是系统的敏感目录或文件。

当你将该文件或目录挂载到容器时，由于 Docker 具有管理权限，所以能够删除挂载的目录或文件，这是很严重的问题。所以，即使使用 `bind mount` 也应该单
独建立一个非系统性质的文件或文件夹。相比之下，volume 是完全由 Docker进行管理，在安全性方面得以保障。而且 volume 更有利于数据备份、迁移和回复。

与 volume 相同，在实现上都有 `--volume` 和 `--mount` 语法。从以上的示例中可以看出，`--mount` 语法相比之下更加清晰简单益于理解。所以在实际
应用中还是应该以 `--mount` 语法为主。对新手来说，推荐使用 `--mount` 语法。