# 前言

理想情况下，容器的可写层即使使用也应该只存储很小的一部分数据，存储数据应该使用 Docker 卷（`volume`）或者挂载方式。不过，在某些工作负载还是要求
你能够将数据写入容器的可写层，这就是存储驱动的用武之地！

Docker 使用可拔插架构支持多种不同的存储驱动程序。存储驱动程序控制 Docker 镜像和容器的存储与管理。之前已经简单介绍了存储驱动，这里就介绍如何根据
场景需要选择最优的存储驱动。

如果你的操作系统内核支持多种存储驱动，那么在 Docker 没有配置存储驱动的情况下，Docker 有一个存储驱动优先级列表，并会自动配置优先级最高的存储驱动。

总体来说，存储驱动会有性能和稳定性两种场景，也是大多数情况下需要考虑的。

Docker 支持如下几种存储驱动程序：

- `overlay2` 存储驱动是当前 Linux 发信版首选的存储驱动程序，无需额外的配置。
- `aufs` 存储驱动是运行于 Ubuntu 14.04 、3.13内核上的存储驱动。同时也是 Docker 18.06 以及更早版本的首选存储驱动程序，因为这些版本不支持 `overlay2` 存储驱动。
- `devicemapper` 存储驱动，在生产环境中使用时需要 `direct-lvm`，因为在零配置下 `loopback-lvm` 性能很烂。`devicemapper` 存储驱动也是
`CentOS` 和 `RHEL` 首选的存储驱动，因为这些发行版本内核不支持 `overlay2`。不过，当前的 `CentOS` 和 `RHEL` 发行版本已经支持 `overlay2`
存储驱动程序，所以 `devicemapper` 存储驱动已经不再是推荐首选的驱动程序。
- `btrfs` 和 `zfs` 存储驱动程序主要用于后备文件系统（安装 Docker 的主机的文件系统）。这些文件系统运行高级选项，例如创建快照，不过同样需要更多
维护和设置。
- `vfs` 存储驱动主要用于测试使用，用于无法使用写时复制（`copy-on-write`）文件系统的情况。该驱动性能极差，生产环境下一定不要使用。

关于存储驱动的定义顺序，可以通过查看 [Docker 源码](https://github.com/docker/docker-ce/blob/18.09/components/engine/daemon/graphdriver/driver_linux.go#L50) 中来了解驱动顺序。

某些存储驱动程序可能会要求你使用特定格式作为后备文件系统。如果你有使用特定支持文件系统的外部要求，你可以参考 [后备文件系统](#后备文件系统)。

# Linux发型版本存储驱动限制

在高级别的配置上，你可以使用的存储驱动取决于 Docker 服务（`Docker Edition`）。

通常，Docker 不建议你禁用操作系统安全功能的配置。例如，如果你在 ContOS 上使用 `overlay` 或 `overlay2` 驱动程序，则需要禁用 `selinux`。

# Docker EE-CE 存储驱动限制

对于 Docker EE-CE，一些配置还处于测试阶段。你的操作系统内核可能不支持所有存储驱动程序。下面列出的存储驱动程序使用于最新的 Linux 发行版本：

|Linux 发行版本|推荐存储驱动|可选存储驱动|
|:-----------|:---------|:---------|
|Docker EE - CE（Ubuntu）| `overlay2` 或 `aufs`(Ubuntu 14.04、kernel 3.13)|`overlay`¹ `devicemapper`² `zfs` `vfs`|
|Docker EE - CE（Debian）| `overlay2` (Debian Stretch)、`aufs` 或 `devicemapper` (旧版) | `overlay`¹ `vfs` |
|Docker EE - CE（CentOS）| `overlay2` | `overlay`¹ `devicemapper`² `zfs` `vfs` |
|Docker EE - CE（Fedora）| `overlay2` | `overlay`¹ `devicemapper`² `zfs` `vfs` |

- ¹) 在 Docker CE-EE `v18.09` 下，`overlay` 存储驱动已经不建议使用，在后续版本会逐渐被废弃。应使用 `overlay2` 代替 `overlay`。

- ²) 在 Docker CE-EE `v18.09` 下，`devicemapper` 存储驱动同样不建议使用，后续版本也会逐渐被废弃。应使用 `overlay2` 代替 `overlay`。

尽可能的应该使用 `overlay2` 存储驱动，这也是推荐的存储驱动。在首次安装 Docker 时，会默认使用 `overlay2` 存储驱动，以前默认使用 `aufs` 驱动。
如果想要在之后使用 `aufs` 驱动，则需要额外的配置。并且可能需要安装额外的软件包，如 `linux-image-extra`。在 [aufs 驱动程序]() 中会做说明。

# 后备文件系统

后备文件系统位于 `/var/lib/docker/` 目录。某些存储驱动程序仅适用于特定的后备文件系统，可以参考下表：

|存储驱动 |支持的后备文件系统 |
|:------|:---------------|
|`overlay2` `overlay` | `xfs`（ftype=1）  `ext4`
|`aufs`	| `xfs` `ext4`|
|`devicemapper` | `direct-lvm`|
|`btrfs` | `btrfs` |
|`zfs` | `zfs` |
|`vfs` |所有文件系统 |

# 扩展

每个存储驱动都有自己的性能特性，或多或少的适合不同的工作负载：

- `overlay2`、`aufs` 和 `overlay` 都是文件级操作而不是块级操作。这可以更有效地使用内存，但容器的可写层在写入繁重的工作负载中可能会变得非常大。
- 块级存储驱动程序（如 `devicemapper`、`btrfs` 和 `zfs`）可以更好地处理大量写入工作负载（尽管不如Docker卷）。
- 对于许多具有多个层或深层文件系统的小写或容器，`overlay` 可能比 `overlay2` 表现更好，但消耗更多索引节点（`inode`），甚至导致 `inode` 耗尽。
- `btrfs` 和 `zfs` 会需要大量内存。
- `zfs` 是 `PaaS` 等高密度工作负载的理想选择。

大多数情况下，稳定性比性能更重要。虽然这里提到的所有存储驱动程序都是稳定的，但有些处于更新、开发中。通常，`overlay2`，`aufs`，`overlay` 和 `devicemapper` 是具有最高稳定性。

**查看存储当前存储驱动：**

如果你是知道当前 Docker 正在使用的存储驱动，你可以使用 `docker info` 命令查看 `Storage Driver` 中的信息，如下：

```
$ docker info
...
Storage Driver: overlay2
 Backing Filesystem: xfs
 Supports d_type: true
 Native Overlay Diff: true
...
```