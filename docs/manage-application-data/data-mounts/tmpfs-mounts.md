# 前言

使用 `volume` 和 `bind` 挂载可以实现在主机与容器之间共享数据。因为数据独立于容器之外，因此即使容器被停止或删除数据也会被持久化。

除此之外，在 Linux 下，还有第三种挂载方式：`tmpfs`。

与 `volume` 和 `bind` 挂载不同，虽然 `tmpfs` 也是独立于容器之外保存数据但是它是临时的！因为 `tmpfs` 是将数据保存在内存中，而不是系统硬盘中。
所以，当容器被终止时，`tmpfs` 挂载同样会被删除，并且修改的文件也不会被持久化保存！

![](./_images/types-of-mounts-tmpfs.png)

得益于 `tmpfs` 的工作方式，这对于仅仅想要临时保存敏感数据或文件而不是将数据持久化的保存在机器硬盘或容器的可写层很有用。

# --tmpfs 和 --mount

一直以来，`--tmpfs` 主要应用于独立容器，而 `--mount` 主要应用与 `swarm` 服务集群。自 Docker `v17.06` 之后，`--mount` 同样可以在独立容
器中使用。 `--mount` 语法更加清晰和益于理解，它与 `--tmpfs` 最大的不同是：`--tmpfs` 不支持任何可配置选项！

+ `--tmpfs`：`tmpfs` 挂载不允许你指定任何配置选项，并且只能应用在独立容器。
+ `--mount`：由多个键值对组成，用逗号分隔，每个键值对由一个 `<key>=<value>` 元组组成。有如下几个配置项：
  - `type`：`mount` 类型，有 `bind`、`vulome` 和 `tmpfs`，本节介绍 `tmpfs`。
  - `destination`：将 `tmpfs` 挂载在容器中的路径，也可以使用 `dst` 和 `target` 替换 `destination`。
  - `tmpfs-type` 和 `tmpfs-mode` 见下文。
  
# --tmpfs 和 --mount 的行为差异

- `--tmpfs` 不允许指定任何配置项！
- `--tmpfs` 不能在 `swarm` 集群中使用，只允许在独立容器中使用，在 `swarm` 集群中只能使用 `--mount`！

# 在容器中使用 tmpfs

在容器中实现 `tmpfs` 挂载需要使用 `--tmpfs` 标识进行说明。另外，你也可以使用 `--mount` 标识 `type` 值为 `tmpfs` 和 `destination`
的组合选项实现 `tmpfs` 挂载。`tmpfs` 挂载没有 `source`，见下面一个示例，分别使用 `--mount` 和 `--tmpfs` 在 `Nginx` 容器中创建一个
`tmpfs` 挂载，挂载在容器的 `/app` 目录。

<!--sec data-title="--mount 示例" data-id="section0" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name tmptest \
  --mount type=tmpfs,destination=/app \
  nginx:latest
```
<!--endsec-->

<!--sec data-title="--tmpfs 示例" data-id="section1" data-show=true ces-->
```
$ docker run -d \
  -it \
  --name tmptest \
  --tmpfs /app \
  nginx:latest
```
<!--endsec-->

运行示例后使用 `docker container inspect <container-id 或 container-name>` 指令并查看 `Mounts` 中的内容挂载类型是否为 `tmpfs`：

```
"Mounts": [
    {
        "Type": "tmpfs",
        "Source": "",
        "Destination": "/app",
        "Mode": "",
        "RW": true,
        "Propagation": ""
    }
]
```

验证成功后进行停止并删除容器

```
$ docker container stop tmptest

$ docker container rm tmptest
```

# tmpfs 选项

`tmpfs` 挂载有如下两个选项，两个都不是必须选项，如果想要指定如下选项只能使用 `--mount`，`--tmpfs` 不支持任何选项！因此，即使使用 `tmpfs`
挂载，也推荐使用 `--mount type=tmpfs` 替代 `--tmpfs`。

|选项|说明|
|:--:|--|
|`tmpfs-size`|`tmpfs` 挂载数据大小（`byte`），默认不做限制|
|`tmpfs-mode`|八进制的 `tmpfs` 文件模式，如：`700` 或 `0770`，默认是 `1777` 或（`worls-writable`）|

下面的示例将 `tmpfs-mode` 设置为 `1770`，这样它在容器中就不是  world-readable。

```
$ docker run -d \
  -it \
  --name tmptest \
  --mount type=tmpfs,destination=/app,tmpfs-mode=1770 \
  nginx:latest
```

# 总结

`tmpfs` 挂载的实现方式有 `--tmpfs` 和 `--mount type=tmpfs` 两种。`--tmpfs` 不支持任何配置选项，并且只能应用与独立容器。所以，在使用 `tmpfs`
挂载时 `--mount type=tmpfs` 是推荐的实现方式！