# 前言

OverlayFS 是一个联合文件系统，类似 AUFS，但速度更快实现更简单。Docker 为 OverlayFS 提供两种存储驱动，分别是原始的 `overlay` 和更新更稳定
的 `overlay2`。

这里将 Linux 内核驱动程序成为 OverlayFS,Docker 存储驱动称为 `overlay` 和 `overlay2`。

> **[info] 小提示**
>
> 如果你使用 OverlayFS，应该使用 `overlay2` 而不是 `overlay`，因为 `overlay2` 在索引节点（`inode`）利用率方面更加高效。
> 如果使用新驱动程序，需要使用版本 4.0 或更高版本的 Linux 内核，或使用版本 3.10.0-514 及更高版本的 RHEL 或 CentOS。可以使用如下命令检查：
```
$ uname -sr
Linux 3.10.0-957.5.1.el7.x86_64
```

<!--sec data-title="使用条件" data-id="section0" data-show=true ces-->
想要知道机器是否支持 OverlayFS，你只需要验证机器是否满足如下条件即可：

- Docker CE-EE `v17.06.02-ee5` 及更高版本支持 `overlay2` 存储驱动，并且 `overlay2` 也是推荐的存储驱动程序。
- Linux 内核 `v4.0` 及更高版本或者 RHEL、CentOS `v3.10.0-514` 及更高内核版本。如果你使用底版本你只能使用 `overlay` 驱动，不推荐使用！
- 更改存储驱动程序会使本地系统上现有的容器和镜像无法访问。在更改存储驱动之前，需要使用 `docker save` 保存本地构建的镜像或将他们推送到 Docker Hub
或私有仓库，这样就不需要在更改驱动后重新创建了。
- `xfs` 后备文件系统支持 `overlay` 和 `overlay2` 驱动，不过需要开启 `d_type=true` 配置。

使用 `xfs_info` 验证 `ftype` 是否设置为1，要正确格式化 `xfs` 文件系统，需要使用 `-n ftype=1` 标识。

> **[danger] 注意**
>
> 在没有 `d_type` 支持的 `XFS` 上运行会导致 Docker 跳过尝试使用 `overlay` 或 `overlay2` 驱动程序。即使安装并运行，但会产生错误。这是为
了允许用户迁移他们的数据。在之后的版本中，这将是一个致命的错误，这它会阻止 Docker 启动。
<!--endsec-->

# OverlayFS 驱动配置

相比之下，`overlay2` 是强烈推荐使用的 OverlayFS 存储驱动方式。另外在 Docker EE 中 `overlay` 是不支持的。

要配置 Docker `overlay` 驱动，Docker 宿主机器 Linux 内核版本不等低于 `v3.18`。同样的，支持`overlay2` 的内核版本不能低于 `v4.0`。

下面是配置 `overlay2` 存储驱动方式，如果想要配置 `overlay` 驱动，指定即可。

- 停止 Docker 服务

```
$ sudo systemctl stop docker
```

- 备份原始 Docker 目录（必须操作！在使用任何驱动程序都应该讲原始加以备份）

```
$ cp -au /var/lib/docker /var/lib/docker.bk
```

- 如果想要从 `/var/lib` 分出单独的后备文件系统，格式化文件系统并将其挂载到 `/var/lib/docker`。要确保将其挂载到 `/etc/fstab` 下以使其持久化。
- 修改 `/etc/docker/daemon.json` 文件（如果没有该文件就创建该文件，并将下面的内容增加到文件中。如果该文件已存在，确保将对应的驱动属性数据修改成下面的内容）

```json
{
  "storage-driver": "overlay2"
}
```

> 如果使用 `overlay` 驱动这里讲 `overlay2` 替换即可：
```json
{
  "storage-driver": "overlay"
}
```

笔者当前没有 `daemon.json` 文件，就创建改文件并将上诉内容增加到文件中：
```
$ cat /etc/docker/daemon.json 
{
  "storage-driver": "overlay2"
}
```

**注意：** `daemon.json` 文件数据格式是 `json`，如果格式错误将对导致 Docker 启动失败！

- 启动 Docker

```
$ sudo systemctl start docker
```

- 验证 `daemon.json` 文件中的配置生效，使用 `docker info` 命令查看 `Storage Driver` 和 `Backing filesystem` 信息：

```
$ docker info
...
Storage Driver: overlay2
 Backing Filesystem: xfs
 Supports d_type: true
 Native Overlay Diff: true
...
```

现在，Docker 就已经切换到了 `overlay2` 驱动，并自动的创建了 `overlay` 挂载必须的结构体 `lowerdir`、`upperdir`、`merged` 和 `workdir`。

下面就说下 OverlayFS 在 Docker 容器中是如何工作的以及有关与不同后备文件系统兼容性的限制和性能相关问题。

# overlay2 是如何工作的

OverlayFS 将单个 Linux 主机上的两个目录分层，并将它们显示为单个目录。这些目录称为 层（`layers`） 和一个统一过程 联合安装（`union mount`）。
OverlayFS 将下层目录称为 `lowerdir`，将上层目录称为 `upperdir`。统一视图通过名为 `merged` 的对外公开。

`overlay2` 驱动程序本身支持多达 128 个较低的 OverlayFS 层。此功能为与层相关的 Docker 命令（如 `docker build` 和 `docker commit`）提
供了更好的性能，并且在后备文件系统上消耗的索引节点（inode）更少。

## 磁盘中镜像和容器层

在说明之前，你可以先使用 `docker pull ununtu` 命令拉取镜像，会拉取四个层。并且，你可以下 `/var/lib/docker/overlay2` 下看到五个目录。

> **[danger] 注意**
>
> 千万不要直接操作 `/var/lib/docker/` 目录下的任何文件或目录。这些文件和目录应该由 Docker 进行管理。

```
$ docker pull ubuntu

Using default tag: latest
latest: Pulling from library/ubuntu
// 拉取四个层
6cf436f81810: Pull complete 
987088a85b96: Pull complete 
b4624b3efe06: Pull complete 
d42beb8ded59: Pull complete 
Digest: sha256:7a47ccc3bbe8a451b500d2b53104868b46d60ee8f5b35a24b41a86077c650210
Status: Downloaded newer image for ubuntu:latest
```

`/var/lib/docker/overlay2/` 目录下有五个目录：
```
$ ls -l /var/lib/docker/overlay2/
总用量 0
drwx------. 4 root root     55 3月  10 21:49 2c6053a92a43d11075a97f6f1163291136e3e3b3048a5fbf2a827e6de58335b2
drwx------. 3 root root     30 3月  10 21:49 60885d52d70041a2fc81c561613081f2bd4bd79b1e087ee172778d3d747cdb51
drwx------. 4 root root     55 3月  10 21:49 847a340d026320518f0bc9aa016702dc638d1d5658e7a33cc9c319065ac90f41
drwx------. 4 root root     55 3月  10 21:49 a9807a86421c1de995ea8424d3092657b83cab21f51c7631c82b8bd913b32a21
drwx------. 2 root root    142 3月  10 21:49 l
```

`l` （小写L）目录包含缩短的层标识作为符号链接。这些标识符用于避免命中 `mount` 命令的参数的页面的大小限制。

```
$ ls -l /var/lib/docker/overlay2/l/
总用量 0
lrwxrwxrwx. 1 root root 72 3月  10 21:49 4NFNLJQJYXFKMDCRIFRYE5NUQG -> ../a9807a86421c1de995ea8424d3092657b83cab21f51c7631c82b8bd913b32a21/diff
lrwxrwxrwx. 1 root root 72 3月  10 21:49 7BBAM4TGEOZMWNDJK7MRJOELLV -> ../847a340d026320518f0bc9aa016702dc638d1d5658e7a33cc9c319065ac90f41/diff
lrwxrwxrwx. 1 root root 72 3月  10 21:49 JQ2UT5CIVGU6SNFX3YU6L27KU2 -> ../2c6053a92a43d11075a97f6f1163291136e3e3b3048a5fbf2a827e6de58335b2/diff
lrwxrwxrwx. 1 root root 72 3月  10 21:49 YAXVQXNLO6EEJAOM2ICFCXD27Q -> ../60885d52d70041a2fc81c561613081f2bd4bd79b1e087ee172778d3d747cdb51/diff
```

最低层包含一个名为 `link` 的文件，其中包含缩短标识符的名称，以及一个名为 `diff` 的目录，其中包含图层的内容。

```
$ ls /var/lib/docker/overlay2/60885d52d70041a2fc81c561613081f2bd4bd79b1e087ee172778d3d747cdb51/

diff  link

$ cat /var/lib/docker/overlay2/60885d52d70041a2fc81c561613081f2bd4bd79b1e087ee172778d3d747cdb51/link 

YAXVQXNLO6EEJAOM2ICFCXD27Q

$ ls /var/lib/docker/overlay2/60885d52d70041a2fc81c561613081f2bd4bd79b1e087ee172778d3d747cdb51/diff/

bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

第二低的层和每个更高层包含一个名为 `lower` 的文件，表示其父级，以及一个名为 `diff` 的目录，其中包含其内容。它还包含一个 `merged` 目录，其中
包含其父层和它自身的统一内容，以及一个由 OverlayFS 内部使用的 `work` 目录。

```
$ ls /var/lib/docker/overlay2/a9807a86421c1de995ea8424d3092657b83cab21f51c7631c82b8bd913b32a21/

diff  link  lower  work

$ cat /var/lib/docker/overlay2/a9807a86421c1de995ea8424d3092657b83cab21f51c7631c82b8bd913b32a21/lower 

l/YAXVQXNLO6EEJAOM2ICFCXD27Q

$ ls /var/lib/docker/overlay2/a9807a86421c1de995ea8424d3092657b83cab21f51c7631c82b8bd913b32a21/diff/
etc  sbin  usr  var
```

> **如何知道高低目录？**
>
> 你可以通过查看 `lower` 中的内容，当前是第二底的目录，再高一级的目录中会包含下级和本身的信息，如下：
```
$ cat /var/lib/docker/overlay2/2c6053a92a43d11075a97f6f1163291136e3e3b3048a5fbf2a827e6de58335b2/lower 
l/4NFNLJQJYXFKMDCRIFRYE5NUQG:l/YAXVQXNLO6EEJAOM2ICFCXD27Q
```

# overlay 是如何工作的

下图显示了 Docker 镜像和 Docker 容器的分层方式。镜像层是 `lowerdir`，容器层是 `upperdir`。统一视图通过名为 `merged` 的目录对外公开，
该目录实际上是容器挂载点。该图显示了 Docker 如何构造镜像到OverlayFS结构。

![](./_images/overlay_constructs.jpg)

在镜像层和容器层包含相同文件的情况下，容器层 “获胜” 并且隐藏镜像层中相同文件的存在。

`overlay` 驱动程序仅适用于两层。这意味着多层图像不能实现为多个OverlayFS层。相反，每个图像层都在 `/var/lib/docker/overlay` 中。然后使用
硬链接作为参考与较低层共享的数据的节省空间的方式。硬链接的使用导致过度使用 inode ，这是传统覆盖存储驱动程序的已知限制，并且可能需要对备份文件系
统进行额外配置。

创建一个容器时，`overlay` 驱动程序会组合表示镜像顶层的目录以及容器的新目录。镜像顶层是 `overlay` 中的 `lowerdir`，并且是只读的。容器的新目
录是 `upperdir` 并且是可写的。

## 磁盘中镜像和容器层

在测试之前需要将驱动切换为 `overlay`！

以下 `docker pull` 命令显示Docker主机下载包含四个层的Docker镜像。

```
$ docker pull ubuntu

Using default tag: latest
latest: Pulling from library/ubuntu
6cf436f81810: Pull complete 
987088a85b96: Pull complete 
b4624b3efe06: Pull complete 
d42beb8ded59: Pull complete 
Digest: sha256:7a47ccc3bbe8a451b500d2b53104868b46d60ee8f5b35a24b41a86077c650210
Status: Downloaded newer image for ubuntu:latest
```

每个图像层在 `/var/lib/docker/overlay/` 中都有自己的目录，其中包含其内容，如下所示。图像层ID与目录ID不对应。

```
ls -l /var/lib/docker/overlay
总用量 0
drwx------. 3 root root 18 3月  10 22:35 108ac4645c66ca4195f3613f009f63adc64f2accd20158e9a820e43c9f37f413
drwx------. 3 root root 18 3月  10 22:35 5e40606e8bb83480bb571ddc5303ea712cd12d08f15a17ecf9afe3b753668299
drwx------. 3 root root 18 3月  10 22:35 7b1546867f6ebc26338ced4b21ab724cb0c3dc94429f5621f184ba23165c461d
drwx------. 3 root root 18 3月  10 22:35 e5be85235be7c781bef9235392c859fc1e7f1ec683c793da1dad83be35bb4859
```

**镜像层**

镜像层目录包含该层唯一的文件以及与较低层共享的数据的硬链接。这会有效使用磁盘空间：

```
$ ls -i /var/lib/docker/overlay/108ac4645c66ca4195f3613f009f63adc64f2accd20158e9a820e43c9f37f413/root/bin/ls

34284624 /var/lib/docker/overlay/108ac4645c66ca4195f3613f009f63adc64f2accd20158e9a820e43c9f37f413/root/bin/ls

// 剩下三次与该层同样，不做演示
```

**容器层**

容器也存在于 `/var/lib/docker/overlay/` 下的Docker主机文件系统中的磁盘上。如果使用 `ls -l` 命令列出正在运行的容器的子目录，则存在三个目录
和一个文件：

```
$ ls -l /var/lib/docker/overlay/<directory-of-running-container>

total 16
-rw-r--r-- 1 root root   64 Jun 20 16:39 lower-id
drwxr-xr-x 1 root root 4096 Jun 20 16:39 merged
drwxr-xr-x 4 root root 4096 Jun 20 16:39 upper
drwx------ 3 root root 4096 Jun 20 16:39 work
```

`lower-id` 文件包含容器所基于的图像顶层的ID，即 Ove​​rlayFS `lowerdir`。

```
$ cat /var/lib/docker/overlay/ec444863a55a9f1ca2df72223d459c5d940a721b2288ff86a3f27be28b53be6c/lower-id

5e40606e8bb83480bb571ddc5303ea712cd12d08f15a17ecf9afe3b753668299
```

`upper` 目录包含容器的读写层的内容，它对应于 OverlayFS `upperdir`。

`merged` 目录是 `lowerdir` 和 `upperdir` 的联合安装，它包含正在运行的容器内的文件系统视图。

`work` 目录是OverlayFS的内部。

# 容器读写如何与 overlayFS 工作