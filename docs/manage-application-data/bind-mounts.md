# 前言

自 Docker 早起，绑定挂载（`bind mounts`）就已经存在。想对于使用 [volumes](./volumes.md)，绑定挂载具有有限的功能，并且安全性也无法得到保障。
当你使用绑定挂载（`bind mounts`）时，主机上的一个文件或者目录就会被挂载到容器中。文件可以是主机上的相对路径或完整路径。相反，当你使用 volumes 时，
会在主机上的 Docker 存储目录创建一个新目录，Docker 会管理该目录的内容。

该文件或目录不需要已存在于 Docker 主机上，在使用绑定挂载（`bind mounts`）时会按需创建文件或目录。绑定挂载（`bind mounts`）非常高效，但它依赖
于具体特定的目录结构的主机文件系统。如果在开发新的 Docker 应用程序时，应该优先考虑使用命名卷（`named volumes`），因为无法直接使用 Docker CLI
命令进行直接管理绑定挂载（`bind mounts`）的装入。

![types-of-mounts-bind.png](./_images/types-of-mounts-bind.png)

# -v 和 --mount 的选择

一直以来，`-v` 或 `--volume` 选项一直使用于独立容器，`--mount` 选项则是使用于 `swarm` 集群服务中。不过，从 Docker `v17.06` 开始，`--mount` 
同样使用于独立容器。通常，`--mount` 使用起来显得更加明确和详细。他们之间最大的区别在于 `-v` 语法将所有选项组合在一个字段中，而 `--mount` 语法
则将他们分开。

> **[info] 小提示**
>
> 新手应该尝试使用 `--mount` 语法，因为该语法使用起来比 `--volume` 更加简单。

+ `-v` 或 `--volume`：由三个字段组成，用冒号（`:`）分隔。字段必须按正确的顺序排列，并且每个字段的含义不是很明显。
  - 对于绑定挂载（`bind mounts`），第一个字段是主机上文件或目录的路径（相对或绝对路径）。
  - 第二个字段是文件或目录在容器中安装的路径。
  - 第三个字段是可选字段。用逗号分隔的选项列表，如：`ro`、`consistent`、`delegated`、`z` 和 `Z`。
  
+ `--mount`：由多个键值对组成，用逗号（`,`）分隔。每个键值由 `<key>=<value>` 元组组成。`--mount` 语法比 `-v` 或 `--volume` 更加详细，
但键的顺序并不重要，并且标识的值更加容易理解。
  - `type` 字段（即 `mount` 的类型，下文省略）可以是 `bind`、`volume` 或 `tmpfs`。本节主题讨论绑定挂载，因此类型始终是 `bind`。
  - `source` 字段。对于绑定挂载（`bind mounts`），这个字段值是 Docker 服务主机上的文件或目录路径，`source` 或 `src` 都是可以的。
  - `destination` 字段其值是挂载的容器中的路径（即容器内部的路径）。另外，`destination` 也可以由 `dst` 或 `target` 代替。
  - `readonly` 选项。如果存在，则导致绑定挂载以只读的方式安装到容器中。
  - `bind-propagation` 字段是可选的。主要作用是绑定传播（`bind propagation`），可以是 `rprivate`、`private`、`rshared`、`shared`、`rslave`、`slave` 中的其中一个。
  - `consistency` 选项，此设置仅适用于Docker Desktop for Mac，在所有其他平台上均被忽略。可以是 `consistent`、`delegated` 或 `cached`。
  - `--mount` 不支持 `z` 或 `Z` 来修改 `selinux` 标签。
  
# -v 和 --mount 之间的行为差异

因为 `-v` 和 `--volume` 选项长期以来一直是 Docker 的一部分，所以他们的行为无法改变。这意味着 `-v` 和 `--mount` 之间存在一种不同的行为。

如果你使用 `-v` 或 `--volume` 进行绑定宿主机上不存在的文件或目录，`-v` 会自动创建一个端点。**它始终作为目录进行创建。**

如果你使用 `--mount` 进行绑定宿主机上不存在的文件或目录，Docker **不会自动的创建**，但是会输出错误信息。

# 使用绑定挂载运行容器

假设你有一个目录 `source`，并且在构建源码时，所做的工件能够保存到另外一个目录 `source/target/`。你想要将工件应用与容器的 `/app` 目录，并且你
希望每次在你的开发主机上构建源时容器都能够访问最新的构建。

使用如下命令将 `target/` 目录绑定到 `/app/` 目录，从 `source` 目录运行该命令。`$(pwd)` 是 linux 上的子命令，表示当前工作目录。

```bash
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  nginx:latest
```

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

如果你绑定挂载一个非空的目录到容器，则绑定挂载会隐藏目录的现有内容。这有一点好处，比如你想要在不构建新镜像的基础上测试一个新版本的应用程序。但是，
它可能令人惊讶，并且此行为与 docker 卷的行为不同。

用主机上的 `/tmp/` 目录替换容器的 `/usr/` 目录的内容，这个例子设计得极端。在大多数情况下，这会导致容器无法运行。

```bash
$ docker run -d \
  -it \
  --name broken-container \
  --mount type=bind,source/tmp,target=/usr \
  nginx:latest
  
688d4fe924fb60a48d256257526cc0172749ba0fd2c68ac721a41e4e59e9fc0f
docker: Error response from daemon: OCI runtime create failed: container_linux.go:344: starting container process caused "exec: \"nginx\": executable file not found in $PATH": unknown.
```
所以，容器虽然被创建了，但是无法运行。最后删除它：

```
$ docker container rm broken-container
```

# 使用只读挂载

大多数情况下，部署一个应用程序容器需要在绑定挂载中进行写文件，所以更改会传播到 Docker 宿主机。在有些时候，容器可能只需要读访问权限即可。

此示例修改上面的一个，但是通过在容器中的挂载点之后将 `ro` 添加到（默认为空）选项列表，将目录挂载为只读绑定挂载。如果存在多个选项，请用逗号分隔。

```bash
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app,readonly \
  nginx:latest
```

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

```bash
$ docker container stop devtest

$ docker container rm devtest
```

# 配置绑定传播机制

绑定传播默认是 `rprivate` 在绑定装入（`bind mounts`）和卷（`volumes`）上。它仅可用于绑定装入，并且仅适用于Linux主机。绑定传播是一个高级主题，
大多数用户永远不需要配置它。

**绑定传播是指在给定的绑定装载或命名卷中创建的装载是否可以传播到该装载的副本。** 考虑一个安装点 `/mnt`，它也安装在 `/tmp` 上面。传播设置控制是
否 `/tmp/a` 也可以使用挂载 `/mnt/a`。每个传播设置都有一个递归对位。在递归的情况下，请考虑将 `/tmp/a` 其挂载为 `/foo`。传播设置控制是
否 `/mnt/a` 或 `/tmp/a` 将存在。

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

```bash
$ docker run -d \
  -it \
  --name devtest \
  --mount type=bind,source="$(pwd)"/target,target=/app \
  --mount type=bind,source="$(pwd)"/target,target=/app2,readonly,bind-propagation=rslave \
  nginx:latest
```

现在，如果你创建 `/app/foo`，`/app2/foo` 也会存在。

<!--sec data-title="使用 -v" data-id="section0" data-show=true ces-->

```bash
$ docker run -d \
  -it \
  --name devtest \
  -v "$(pwd)"/target:/app \
  -v "$(pwd)"/target:/app2:ro,rslave \
  nginx:latest
```

效果等同 `--mount` 传播。
<!--endsec-->