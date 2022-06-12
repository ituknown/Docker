在构建镜像时我们一般都会选取一个基础镜像，这个基础镜像可以是自定义的一个镜像也可以是一个官方提供的镜像。

个人玩 Docker 构建 Java 服务的话通常会选取 OpenJDK 作为基础镜像最为合适，今天在自己玩镜像的时候选取了 OpenJDK8 作为基础镜像：

```dockerfile
FROM openjdk:8
```

在系统中使用 docker 运行时发现一个小问题，就是这个 OpenJDK 基础镜像基于当前操作系统。

如果你使用的操作系统是 Ubuntu，你就会发现 pull 的这个 openjdk 基础镜像基于的操作系统就会是 Ubuntu：

```bash
$ hostnamectl
   Static hostname: ubuntu-vm
         Icon name: computer-vm
           Chassis: vm
        Machine ID: 7da0e1f1ec8746618642ed223a2cdfe7
           Boot ID: b61f424a99b049d0b0b74dd31fb63ec8
    Virtualization: microsoft
  Operating System: Ubuntu 20.04.2 LTS
            Kernel: Linux 5.4.0-77-generic
      Architecture: x86-64

$ docker run --rm -it openjdk:8 /bin/bash
root@bdea7728d71d:/# uname -a
Linux bdea7728d71d 5.4.0-77-generic #86-Ubuntu SMP Thu Jun 17 02:35:03 UTC 2021 x86_64 GNU/Linux
```

如果使用的操作系统是 Debian，你就会发现这个基础镜像基于的操作系统相应的就会是 Debian：

```bash
$ hostnamectl
   Static hostname: debian10
         Icon name: computer-vm
           Chassis: vm
        Machine ID: 3f4cbce2f0514de9b104205dd384efe1
           Boot ID: b2556fee9f7641bd9c77cbad771e48d8
    Virtualization: microsoft
  Operating System: Debian GNU/Linux 10 (buster)
            Kernel: Linux 4.19.0-17-amd64
      Architecture: x86-64

$ docker run --rm -it openjdk:8 /bin/bash
root@a169fd2ac23d:/# uname -a
Linux a169fd2ac23d 4.19.0-17-amd64 #1 SMP Debian 4.19.194-2 (2021-06-21) x86_64 GNU/Linux
```

这样的话你会发现一个问题，如果你的操作系统的 RHEL 系列，基于 `openjdk` 作为镜像时如果在内部使用了 `apt` 命令就会构建失败。

再比如说，如果我们在构建镜像时 `ENTRYPOINT` 使用了一个 `shell` 脚本，在 `shell` 脚本中我们执行创建用户的命令。你也会发现是有问题的，因为 RHEL 和 Debian 系列的系统创建用户的命令是有些区别的。

所以，在使用基础镜像构建镜像时一定要注意基础操作系统。不然就会出现预料之外的问题~

所以在实际使用中，我会选择基于 Debian 的 openjdk：

```dockerfile
# 基于 debian10 的 openjdk
FROM openjdk:8-jdk-buster

# 基于 debian9 的 openjdk
FROM openjdk:8-jdk-stretch
```
