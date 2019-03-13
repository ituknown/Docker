# 前言

AUFS 是一个联合文件系统。在 ubuntu 操作系统中，`aufs` 之前一直是 docker 默认的存储驱动，以及管理镜像和容器。不过对于 Linux 4.0
或更高版本的内核发型版本，`aufs` 驱动不再是推荐的存储驱动（对于 ubuntu），相反 Docker CE-EE 现在强烈建议使用 `overlay2` 驱动。因为 overlay2
驱动在许多方面都比 `aufs` 更加优秀。

<!--sec data-title="使用条件" data-id="section0" data-show=true ces-->
- 对于 Docker CE，Ubuntu 和 Streth 之前的 Debian 版本支持 AUFS。
- 对于 Docker EE，Ubuntu 支持 AUFS。
- 如果你使用 Ubuntu，需要 [安装额外的软件包](https://docs.docker.com/install/linux/docker-ce/ubuntu/) 以将 AUFS 模块添加到内核中。如果你不安装这些软件包，则需要在 Ubuntu 14.04（不推荐）上使用
`devicemapper`，或者在Ubuntu 16.04及更高版本上使用 `overlay2`，这也是支持的。
- AUFS 不能使用 `aufs`、`btrfs`、或 `ecryptfs` 后备驱动。这意味着包含 `/var/lib/docker/aufs` 的文件系统不能是这些文件系统类型之一。
- 更改存储驱动程序会使本地系统上现有的容器和镜像无法访问。在更改存储驱动之前，需要使用 `docker save` 保存本地构建的镜像或将他们推送到 Docker Hub
或私有仓库，这样就不需要在更改驱动后重新创建了。
<!--endsec-->

# aufs 驱动配置

在 ubuntu 中，在没有显示的配置存储驱动时，Docker 默认使用 AUFS驱动程序（并自动将其加载到内存中）。这里主要介绍 CentOS 如何使用 `aufs` 存储驱动。


- 停止 Docker 服务

```
$ sudo systemctl stop docker
```

- 备份原始 Docker 目录（必须操作！在使用任何驱动程序都应该将原始加以备份）

```
$ cp -au /var/lib/docker /var/lib/docker.bk
```

- 验证 CentOS 是否支持 AUFS，如果你的 CentOS 没有输出如下信息即表示不支持 AUFS，你需要进行相应配置。

```
$ grep aufs /proc/filesystems

nodev   aufs
```

<!--sec data-title="CentOS 不支持 aufs ?" data-id="section1" data-show=true ces-->
如果你是使用 `grep aufs /proc/filesystems` 命令无法得到如下结果说明你的 CentOS 不支持 `aufs` 驱动。

```
$ grep aufs /proc/filesystems
nodev   aufs
```

笔者当前 CentOS 就不支持 `aufs` 驱动，因此需要做如下额外的配置。可以看下步骤：

- 添加 `kernel-ml-aufs.repo` 源，这里笔者使用 `wget` 命令进行下载，如果你当前没有安装 `wget` 可以使用 `yum install -y wget` 命令进行
安装，然后跟随下面步骤即可。

```
# 进入 /etc/yum.repo.d 目录
$ cd /etc/yum.repo.d

# 看下当前目录下的文件
$ ls
CentOS-Base.repo  CentOS-Debuginfo.repo  CentOS-Media.repo    CentOS-Vault.repo
CentOS-CR.repo    CentOS-fasttrack.repo  CentOS-Sources.repo  docker-ce.repo

# 在该目录下下载 kernel-ml-aufs.repo
$ wget https://yum.spaceduck.org/kernel-ml-aufs/kernel-ml-aufs.repo

# 下载完成后就看下是否有该文件
$ ls /etc/yum.repo.d
CentOS-Base.repo       CentOS-fasttrack.repo  CentOS-Vault.repo
CentOS-CR.repo         CentOS-Media.repo      docker-ce.repo
CentOS-Debuginfo.repo  CentOS-Sources.repo    kernel-ml-aufs.repo

# 在 /etc/yum.repo.d 目录下进行安装 kernel-ml-aufs
$ yum install -y kernel-ml-aufs
```

- 修改内核启动

上面的命令执行完成后就开始修改内核，修改 `/etc/default/grub` 文件。

```
# 编辑 grub 文件
$ vim /etc/default/grub
```

该文件没修改之前的内容如下：

```
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
```

你的文件可能跟笔者有些诧异，小细节不必在意。这些配置中你只需要注意其中 `GRUB_DEFAULT=saved` 的配置即可，`saved` 表示下次启动时默认启动上次
的内核。我们需要将其修改为 0，表示启动时选择第一个内核：

```
GRUB_DEFAULT=0
```

修改完成后保存并退出：`:wq`。

接着执行如下命令是配置生效：

```
$ grub2-mkconfig -o /boot/grub2/grub.cfg
```

- 最后重启计算机：

```
$ reboot
```

- 重启完成后再次执行 `grep aufs /proc/filesystems` 命令，看是否得到如下输出信息。即使不输出如下信息也不一定是没有配置成功，输出只是提示你
配置成功。当你第一次安装 docker 并没有显示的配置其他存储驱动时一般执行如下命令并不会有任何输出，实际上已经配置完成。

```
$ grep aufs /proc/filesystems
nodev	aufs
```

> 另外，你也可以参考： [Github kernel-ml-aufs](https://github.com/bnied/kernel-ml-aufs)

<!--endsec-->

- 修改 `/etc/docker/daemon.json` 文件（如果没有该文件就创建该文件，并将下面的内容增加到文件中。如果该文件已存在，确保将对应的驱动属性数据修改成下面的内容）

```json
{
  "storage-driver": "aufs"
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
Storage Driver: aufs
 Root Dir: /var/lib/docker/aufs
 Backing Filesystem: xfs
 Dirs: 4
 Dirperm1 Supported: true
...
```

> 如果你之前使用的是其他存储驱动程序，则内核中不包含 AUFS（在这种情况下使用不同的默认驱动程序），或者已将 Docker 明确配置为使用其他驱动程序。检查 
`/etc/docker/daemon.json` 或 `ps auxw | grep dockerd` 查看Docker是否已使用 `--storage-driver` 标志启动。

# aufs 是如何工作的

AUFS是一个联合文件系统，意思是它在单个 Linux 主机上分层多个目录并将它们显示为单个目录。这些目录在 AUFS 术语中称为分支（`branches`），
在Docker术语中称为层（`layers`）。

统一过程称为联合安装。

下图显示了基于 `ubuntu:latest` 镜像的Docker容器。

![](./_images/aufs_layers.jpg)

每一个镜像层、容器层都表示 Docker 主机 `/var/lib/docker/` 中的一个子目录。联合挂载提供了所有层的统一视图。目录并不会直接 对应层的 ID。

AUFS使用写时复制（CoW）策略来最大化存储效率并最大限度地减少开销

# 磁盘中镜像和容器层

以下 `docker pull ubuntu` 命令显示Docker主机下载包含四个层的Docker镜像。

```
$ docker pull ubuntu

Using default tag: latest
latest: Pulling from library/ubuntu
898c46f3b1a1: Pull complete 
63366dfa0a50: Pull complete 
041d4cd74a92: Pull complete 
6e1bee0f8701: Pull complete 
Digest: sha256:d019bdb3ad5af96fa1541f9465f070394c0daf0ffd692646983f491ce077b70f
Status: Downloaded newer image for ubuntu:latest
```

> **[danger] 注意**
>
> 千万不要直接操作 `/var/lib/docker/` 目录下的任何文件或目录。这些文件和目录应该由 Docker 进行管理。

有关图像和容器层的所有信息都存储在 `/var/lib/docker/aufs/` 的子目录中。

```
$ ls /var/lib/docker/aufs/
diff  layers  mnt
```

- `diff/`：每个层的内容，每个都存储在一个单独的子目录中。
- `layers/`：有关镜像如何堆叠的元数据信息。该目录包含Docker主机上每个镜像或容器层的一个文件。每个文件都包含堆栈中其下面所有层的ID（其父级）。
- `mnt/`：挂载点，每个映像或容器层一个，用于组装和装载容器的统一文件系统。对于只读的图像，这些目录始终为空。

**容器层**

如果运行一个容器，`/var/lib/docker/aufs/` 的内容会以下列方式更改：

- `diff/`：可写容器层中引入的差异，例如新文件或修改过的文件。
- `layers/`：有关可写容器层的父层的元数据。
- `mnt/`：每个正在运行的容器的统一文件系统的安装点，与容器内的安装点完全相同。

# 容器读写如何与 aufs 协作

<!--sec data-title="读文件" data-id="section2" data-show=true ces-->
容器层读取文件有如下三个场景：

- **文件仅存在于镜像层**

如果容器打开文件以进行读访问，并且容器层中尚不存在该文件，则存储驱动程序将从容器图层正下方的层开始搜索镜像层中的文件。找到文件后直接从镜像层中读取的。

- **文件仅存在于容器层**

如果容器打开文件以进行读访问，并且该文件存在于容器层中，则从该处读取该文件。

- **文件同时存在于容器和镜像层中**

如果容器打开文件以进行读访问，并且该文件存在于容器层和一个或多个镜像层中，则从容器层读取该文件。容器层中的文件模糊（隐藏）了镜像层中同名文件。

<!--endsec-->


<!--sec data-title="修改文件" data-id="section3" data-show=true ces-->
同样，容器层写文件也会存在如下几种场景：

+ **容器层第一次写文件**

容器第一次写入现有文件时，容器（`upperdir`）中不存在该文件。 `aufs` 驱动程序执行 `copy_up` 操作，将文件从存在的图像层复制到可写容器层。然后，
容器将更改写入容器层中的文件的新副本。

注意，AUFS 是文件级而不是块级操作。意识是所有 `copy_up` 操作都会复制整个文件，即使文件非常大并且只修改了其中的一小部分。这会对容器写入性能产生
显着影响。 AUFS 在搜索具有多个图层的图像中的文件时可能会遇到明显的延迟。但是，值得注意的是，`copy_up` 操作仅在第一次写入给定文件时发生。对同一
文件的后续写入操作将对已经复制到容器的文件的副本进行操作。
  
+ **文件重命名**

仅当源路径和目标路径都位于顶层时，才允许为目录调用 `rename（2）`。否则，会返回 `EXDEV` 错误（不允许跨设备链接）。所以你的应用程序需要设计为
处理 `EXDEV` 并回退到 复制和取消链接(`copy and unlink`) 策略。

+ **删除文件：**
  - 在容器中删除文件时，会在容器（`upperdir`）中创建一个 `whiteout` 文件。并不会删除镜像层（`lowerdir`）中的文件（因为`lowerdir`是只读的）。
不过，如果容器想要再次读取该文件时 `whiteout` 文件阻止该操作，因为该文件（容器中的副本）已经被删除了。
  - 在容器中删除目录时，会在容器（`upperdir`）中创建一个 `opaque directory` 目录。与 `whiteout` 文件的工作方式相同，并且有效地防止了目录被
再次访问，虽然它实际上仍然存在于图像（`lowerdir`）中。
<!--endsec-->

# AUFS 的性能问题

- AUFS 存储驱动程序的性能低于 `overlay2` 驱动程序，但对于 PaaS 和容器密度很重要的其他类似用例来说，它是一个不错的选择。这是因为 AUFS 在多个
正在运行的容器之间高效地共享镜像，从而实现快速的容器启动时间和最小的磁盘空间使用。

- AUFS 通过在镜像层和容器之间共享文件的基础机制非常有效地使用页面缓存。

- AUFS 存储驱动程序可能会在容器写入性能方面引入显着的延迟。这是因为容器第一次写入任何文件时，需要找到该文件并将其复制到容器顶部可写层中。当这些
文件存在于许多图像层下方并且文件本身很大时，这些延迟会增加并且复杂化。