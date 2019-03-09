# 前言

存储驱动与挂载（`volume`、`bind`、`tmpfs`）有相似之处 ーー 存储数据！不同之处在于，数据挂载是将数据安装在宿主机器的硬盘中，当容器被删除时，挂载
的数据由于独立于容器所以得以持久化保存。而存储驱动同样也是讲数据保存，不过存储驱动是在容器的可写层中进行保存数据（说的可能太片面，更详细的说应该是
层之间的详细交互信息，见下文）。

因此，存储驱动程序实现的功能是在容器的可写层中创建数据。有一点需要说明：删除容器后，文件将不会保留，并且读取和写入速度都很低。

要想使用存储驱动，你需要知道 Docker 是如何构建、存储镜像以及容器时如何使用镜像的。只有知道这些你才能够选择更好的方式进行持久化数据并避免在此过程
中产生的性能问题。

# 镜像和层

一个镜像是由一系列 <u>层（`layer`）</u> 构建的。每一层代表着 Dockerfile 文件中的一条指令，除了最上面一层每一层都是只读层。看下下面一个栗子：

```
FROM ubuntu:15.04
COPY . /app
RUN make /app
CMD python /app/app.py
```

这个 Dockerfile 包含四条指令，每一条指令都会创建一个层。`FROM` 指令首先声明基于 `ubuntu 15.04` 镜像构建一个层，`COPY` 指令是将 Dockerfile
文件当前目录的文件拷贝到容器的 `/app` 目录，同样的创建了一个层。`RUN` 指令使用 `make` 命令构建你的应用程序。最后，最后一个指令（层）指定在容器
中运行的命令。

所以，上面四条指令一共创建了四个层！而每一层都在前面一层的基础上增加了不同的操作，最新的一层堆叠在上面的一层之上，这其实就是镜像的本质。当你创建一
个新的容器时实际上就是在镜像的最上一层又增加了一个层！注意，构建镜像的层都是只读层（`read-only-layer`）。而构建容器时是在镜像（只读层）之上增加
了一个可写层（`writeable-layer`），这一个可写层通常被称为容器层（`container-layer`），这就是容器和镜像的本质！当你在运行态的容器上的所有操
作（如新增、修改和删除文件）实际上都将写入这个可写层！所以，存储驱动实现的功能就是在容器层上的操作！看下下面一个图例：

![](./_images/container-layers.jpg)

**存储驱动程序处理有关这些层彼此交互方式的详细信息**。存储驱动分多种。在不同场景下都有各自的优缺点。

# 容器和层

镜像和容器之间的最大不同之处在于最上面的可写层。容器中的所有写操作（增加、删除、修改）都是将数据存储在这个可写层中。当容器被删除时，这个可写层响应
的也会被删除，不过可写层之下的只读层（镜像）并不会被删除。

这是因为没一个容器都有自己的可写层，所有的操作都是存储在这个可写层中。多个容器可以共享对同一底层镜像的访问权限，但是仍会具有自己的数据状态（每个容
器的可写层可以理解为是相互独立的），看下下面一张图，表示多个容器共享同一个底层镜像（`ubuntu 15.04`）：

![](./_images/sharing-layers.jpg)

> **[success] 小提示**
>
> 如果多个镜像需要共享数据，则需要使用挂载的方式实现并将其装入容器中。

Docker 使用存储驱动程序来管理镜像和可写容器层的内容。每个存储驱动程序以不同的方式处理实现，不过所有的存储去动程序都使用可堆叠镜像层和写时复制（`copy-on-write`）
策略。

# 容器大小

如果想要查看运行态容器的大致大小，可以使用 `docker ps -s` 命令。示例：

```
$ docker ps -s
CONTAINER ID        IMAGE          ......    SIZE
36e811b7b02b        nginx:latest   ......    2B (virtual 109MB)
```

看到，在 `size` 一栏中显示的是 `2B (virtual 109MB)`。下面说下为什么：

- `size`：该值计算的是容器的可写层的数量量（在磁盘上）。
- `virtual size`：该值计算的是容器的镜像层（`readOnle-payer`）加上镜像层的大小。多个容器存在共享一些或全部的只读层镜像数据（镜像是由层构建，
因此镜像之间也会共享同一只读层）。因此，在计算容器的大小是你不能直接使用只读层加上容器层进行计算容器的大小。真正的容器层是 `size`，所以容器的大小
应该为只读层和容器层的某种区间值，否则会过度估计磁盘总使用量，这可能是一个非常重要的参考数量。

注意，上面两种计算方式不会计算下列数据大小，所以计算容器的大小是也需要参考下列数据大小：

- 如果容器使用 `json-file` 日志记录驱动程序并且灭有配置日志轮换，那么容器可能会在硬盘中产生大量日志数据。
- 容器使用了卷和绑定挂载存储数据。
- 容器的配置文件的大小（一般可忽略不计）。
- 如果启用了内存交换则某些数据会写入磁盘。
- ......

# 写时复制策略

写时复制是一种共享和复制文件的策略，可以最大的提升效率。如果文件或目录存在于镜像中的较低层，而另一层（包括可写层）需要对其进行读访问，则它只使用现
有文件。如果一个层需要修改该文件（之前并没有做个修改），那么文件将会被复制到该层并进行修改（可以理解为当前文件是原始文件的快照版本）。这就最小化 I/O
和每个后续层的大小。

# 共享实现更小镜像

当你使用 `docker pull` 命令从远程拉取仓库镜像时，或当你基于本地不存在的一个镜像构建容器时，每一层都会单独拉取，并存储在 Docker 本地存储区域。
Linux 下通常是在 `/var/lib/docker` 目录下，看下面一个示例：

```
$ docker pull ubuntu:15.04

15.04: Pulling from library/ubuntu
9502adfba7f1: Pull complete 
4332ffb06e4b: Pull complete 
2f937cc07b5f: Pull complete 
a3ed95caeb02: Pull complete 
Digest: sha256:2fb27e433b3ecccea2a14e794875b086711f5d49953ef173d8a03e8707f1510f
Status: Downloaded newer image for ubuntu:15.04
```

这些层中的每一层都存储在 Docker 主机本地存储区域内的自己的目录中。要检查文件系统上的图层，可以使用 `/var/lib/docker/<storage-driver>/`
进行列出，笔者当前使用的是 `overlay2` 驱动：

```
$ ls /var/lib/docker/overlay2/
1887cd2e8d69023032e42d51f07cef3743fe6f5e4352db133fb9cdbbab9562a9
7749482a1da06f7c6573220e4a54ed466b65ddc8ed7ff8651c09f01757f9a950
f13d0da15ce025031796d9516f8146692f4022314baa9085ddd12d225e6067b8
844e322604831727456d8cdf21138e275cd908b425dd946242bb3cd6ad109311
```

如果你发现目录名称与层ID不对应，这是正常现象。你也可以进入 `/var/lib/docker/image/overlay2/distribution/diffid-by-digest/sha256/`
查看签名校验（笔者使用的是 `overlay2` 存储驱动）。

现在通过实现两个镜像进行验证。构建第一个镜像，命名为：`test/my-base-image:1.0`，Dockerfile 内容如下

```
FROM ubuntu:16.10
COPY . /app
```

第二个镜像基于上面一个镜像，不过在其基础上增加一个层：

```
FROM test/my-base-image:1.0
CMD /app/hello.sh
```

第二个镜像包含第一个镜像中的所有层，以及带有 `CMD` 指令的新层和读写容器层。由于第二个所有的层在第一个镜像中都已存在，因此不会重新拉去，两个镜像
之间会共享一些相同的层。

如果你构建从两个 Dockerfile 中构建镜像，你可以使用 `docker image ls` 和 `docker history` 命令验证共享层的加密ID是否相同。

- 创建一个目录 `test`。
- 进入 `test` 目录，创建一个新文件内容如下：
```
#!/bin/sh
echo "Hello world"
```

保存，并为其赋予可执行权限：

```
$ chmod +x hello.sh
```

- 将上面第一个 Dockerfile 的内容复制到名为 `Dockerfile.base` 的新文件中。
- 将上面第二个 Dockerfile 的内容复制到一个名为 `Dockerfile` 的新文件中。
- 进入 `test` 目录，构建第一个镜像。不要忘记在构建语句最后增加 `.`，该指令设置 `PATH`，告诉 Docker 在哪里查找需要添加到镜像的文件。

```
$  ls
Dockerfile.base  hello.sh

$ docker build -t test/my-base-image:1.0 -f Dockerfile.base .

Sending build context to Docker daemon  3.072kB
Step 1/2 : FROM ubuntu:16.10
16.10: Pulling from library/ubuntu
dca7be20e546: Pull complete 
40bca54f5968: Pull complete 
61464f23390e: Pull complete 
d99f0bcd5dc8: Pull complete 
120db6f90955: Pull complete 
Digest: sha256:8dc9652808dc091400d7d5983949043a9f9c7132b15c14814275d25f94bca18a
Status: Downloaded newer image for ubuntu:16.10
 ---> 7d3f705d307c
Step 2/2 : COPY . /app
 ---> c01dd544f76a
Successfully built c01dd544f76a
Successfully tagged test/my-base-image:1.0
```
- 构建第二个镜像

```
$ ls
Dockerfile  Dockerfile.base  hello.sh

$docker build -t test/my-final-image:1.0 -f Dockerfile .

Sending build context to Docker daemon  4.096kB
Step 1/2 : FROM test/my-base-image:1.0
 ---> c01dd544f76a
Step 2/2 : CMD /app/hello.sh
 ---> Running in c46c1f3c1b8a
Removing intermediate container c46c1f3c1b8a
 ---> ab1365048585
Successfully built ab1365048585
Successfully tagged test/my-final-image:1.0
```

可以看到，在构建第二个镜像时输出的日志相比第一个少了许多。因为需要的图层在第一个镜像构建时已经全部拉去的下来。

- 验证镜像大小

```
$ docker image ls
REPOSITORY            TAG                 IMAGE ID            CREATED              SIZE
test/my-final-image   1.0                 ab1365048585        About a minute ago   107MB
test/my-base-image    1.0                 c01dd544f76a        4 minutes ago        107MB
```

- 检查构成每个镜像的图层：

```
$ docker history c01dd544f76a

IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
c01dd544f76a        6 minutes ago       /bin/sh -c #(nop) COPY dir:762fb67d9646a13ea…   60B                 
7d3f705d307c        19 months ago       /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B                  
<missing>           19 months ago       /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B                  
<missing>           19 months ago       /bin/sh -c sed -i 's/^#\s*\(deb.*universe\)$…   2.78kB              
<missing>           19 months ago       /bin/sh -c rm -rf /var/lib/apt/lists/*          0B                  
<missing>           19 months ago       /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   745B                
<missing>           19 months ago       /bin/sh -c #(nop) ADD file:6cd9e0a52cd152000…   107MB
```

```
$ docker history ab1365048585

IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
ab1365048585        3 minutes ago       /bin/sh -c #(nop)  CMD ["/bin/sh" "-c" "/app…   0B                  
c01dd544f76a        6 minutes ago       /bin/sh -c #(nop) COPY dir:762fb67d9646a13ea…   60B                 
7d3f705d307c        19 months ago       /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B                  
<missing>           19 months ago       /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B                  
<missing>           19 months ago       /bin/sh -c sed -i 's/^#\s*\(deb.*universe\)$…   2.78kB              
<missing>           19 months ago       /bin/sh -c rm -rf /var/lib/apt/lists/*          0B                  
<missing>           19 months ago       /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   745B                
<missing>           19 months ago       /bin/sh -c #(nop) ADD file:6cd9e0a52cd152000…   107MB 
```

从上面的结果中看到，除第二个镜像的顶层外，所有图层都相同。所有其他图层在两个镜像之间共享，并且只在 `/var/lib/docker/` 中存储一次。新层实际上
根本不占用任何空间，因为它不会更改任何文件，而只会运行命令。

> **[warning] 小提示**
>
> `docker history` 输出的 `<missing>` 行表示这些层是在另一个系统上构建的，并且在本地不可用。这可以忽略。

# 复制促进高效容器

当启动一个容器，会在基础的镜像层之上增加一个很小的可写层。在容器中所有的写操作都将存储在该层中，容器未更改的文件都不会复制到此可写层，这就保证了尽
可能小的容器。

当修改容器中的现有文件时，存储驱动程序将执行写时复制操作。涉及的具体步骤取决于特定的存储驱动程序。对于 `aufs`，`overlay` 和 `overlay2` 驱动
程序，写时复制操作遵循以下粗略顺序：

- 在镜像层中搜索要修改的文件。该过程从最新层开始，一次一层地向下到底层。找到结果后，会将它们添加到缓存中以加快将来的操作。
- 对找到的文件的第一个副本执行 `copy_up` 操作，以将文件复制到容器的可写层。
- 对此文件副本进行任何修改，容器都无法查看较低层中存在的文件的只读副本。

写入大量数据的容器比不使用容器层的容器占用更多空间。这是因为大多数写入操作会占用容器的可写顶层中的新空间。

> **[danger] 提示**
>
> 对于写入量很大的应用程序，不应将数据存储在容器中。相反，使用 Docker 卷，它独立于正在运行的容器，并且设计为对 `I/O` 有效。此外，卷可以在容器
之间共享，也不会增加容器可写层的大小。

`copy_up` 操作可能会产生明显的性能开销。根据正在使用的存储驱动程序，此开销会有所不同。大文件，大量图层和深层目录树可以使影响更加明显。每个
`copy_up` 操作仅在第一次修改给定文件时发生，这可以减轻这种情况。

为了验证写时复制的工作方式，使用我们之前构建的 `test/ my-final-image1.0` 图像启动5个容器，并检查它们占用多少空间。

- 从 Docker 主机上的终端运行以下 `docker run` 命令。末尾的字符串是每个容器的ID。

```
$ docker run -dit --name my_container_1 test/my-final-image:1.0 bash \
  && docker run -dit --name my_container_2 test/my-final-image:1.0 bash \
  && docker run -dit --name my_container_3 test/my-final-image:1.0 bash \
  && docker run -dit --name my_container_4 test/my-final-image:1.0 bash \
  && docker run -dit --name my_container_5 test/my-final-image:1.0 bash
  
  8c074003b198602a83d7677a013e2ff208c117cc89e96fa89c8a581e3d731e11
  b9c64195580fbd84f85e4926eb8af6ce502108db4147e9e1c1a288f1a2b9f080
  caba846e4623afe266c1b2922ebd51c62e6913e316874f44ffc68cbc0e2443a8
  48c507b5a182dcfba68d6a886d9f1b26602555094b18f1310e1bbb6bc8dec447
  0d2b9b6fd7df2a85fc9031d2cad23c6715c130a8295886b726b391e46974ed39
```

- 使用 `docker ps` 指令验证容器已经运行

```
$ docker ps
CONTAINER ID        IMAGE                     COMMAND             CREATED             STATUS              PORTS               NAMES
0d2b9b6fd7df        test/my-final-image:1.0   "bash"              30 seconds ago      Up 28 seconds                           my_container_5
48c507b5a182        test/my-final-image:1.0   "bash"              31 seconds ago      Up 29 seconds                           my_container_4
caba846e4623        test/my-final-image:1.0   "bash"              32 seconds ago      Up 30 seconds                           my_container_3
b9c64195580f        test/my-final-image:1.0   "bash"              33 seconds ago      Up 31 seconds                           my_container_2
8c074003b198        test/my-final-image:1.0   "bash"              34 seconds ago      Up 32 seconds                           my_container_1
```

- 列出本地存储区域的容器内容

```
$ ls /var/lib/docker/containers/
0d2b9b6fd7df2a85fc9031d2cad23c6715c130a8295886b726b391e46974ed39  
b9c64195580fbd84f85e4926eb8af6ce502108db4147e9e1c1a288f1a2b9f080
48c507b5a182dcfba68d6a886d9f1b26602555094b18f1310e1bbb6bc8dec447  
caba846e4623afe266c1b2922ebd51c62e6913e316874f44ffc68cbc0e2443a8
8c074003b198602a83d7677a013e2ff208c117cc89e96fa89c8a581e3d731e11
```

- 查看这些容器大小

```
$ sudo du -sh /var/lib/docker/containers/*
24K	/var/lib/docker/containers/0d2b9b6fd7df2a85fc9031d2cad23c6715c130a8295886b726b391e46974ed39
24K	/var/lib/docker/containers/48c507b5a182dcfba68d6a886d9f1b26602555094b18f1310e1bbb6bc8dec447
24K	/var/lib/docker/containers/8c074003b198602a83d7677a013e2ff208c117cc89e96fa89c8a581e3d731e11
24K	/var/lib/docker/containers/b9c64195580fbd84f85e4926eb8af6ce502108db4147e9e1c1a288f1a2b9f080
24K	/var/lib/docker/containers/caba846e4623afe266c1b2922ebd51c62e6913e316874f44ffc68cbc0e2443a8
```

每个容器只占用文件系统上32k的空间。

写入时复制不仅节省了空间，而且还减少了启动时间。当你启动容器（或来自同一图像的多个容器）时，Docker只需要创建可写的容器层。

如果Docker每次启动新容器时都必须制作底层映像堆栈的完整副本，则容器启动时间和使用的磁盘空间将显着增加。这类似于虚拟机的工作方式，每个虚拟机有一个
或多个虚拟磁盘。