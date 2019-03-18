# 前言

在实际使用中镜像构建都是通过 Dockerfile 进行构建。Dockerfile 是由一系列命令和参数构成的脚本，这些命令应用于基础镜像并最终创建一个新的镜像。它
们简化了从头到尾的流程并极大的简化了部署工作。Dockerfile 从 `FROM` 命令开始，紧接着跟随者各种方法，命令和参数。其产出为一个新的可以用于创建容器
的镜像。

Dockerfile 文件主要定义容器内的环境中发生的事情。比如对网络接口和磁盘驱动器等资源的访问是在此环境中都是虚拟化的，该环境与系统的其他部分是隔离的，
因此需要将端口映射到外部世界，并具体说明希望将哪些文件 **复制到** 该环境。

**注意：** Dockerfile 是一个文件！

下面就来看下 Dockerfile 中语法的使用：

# 简单示例

在看具体语法与命令之前先看一个简单的栗子，该栗子 Dockerfile 内容如下所示：

```
# This Dockerfile uses the ubuntu as base image
# Version v1.0.0 - EDITION V1
# Author: MinGRn
# Command format: Instruction [arguments / command] ..

# Base image to use, This must be set as first line
FROM ubuntu

# Maintainer: MinGRn <MinGRn97@gmail.com>
Maintainer: MinGRn MinGRn97@gmail.com

# Commands to update the image
RUN echo "deb http://archive.ubuntu.com/ubuntu raring main universe" >> /etc/apt/source.list

RUN apt-get update && apt-get install -y nginx

RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf

# Commands when creating a new container
CMD /use/sbin/njinx
```

<!--sec data-title="说明" data-id="section0" data-show=true ces-->

当使用 Dockerfile 构建镜像时，Dockerfile 第一条有效信息必须是基础镜像信息，即 `FROM`。

维护者信息紧随其后，即 `MAINTAINER`。

而镜像操作指令则在维护者信息之后，即 `RUN`。

因为操作指令不同，自然就会构建出千差万别的镜像来。

最后是镜像的启动指令，它被用作设置镜像的默认启动命令。

**注意：** 在 Dockerfile 文件中注释使用使用 `#`。

<!--endsec-->


# 指令集

从上面的栗子中的 `FROM ubuntu`、`RUN echo ..` 等语句不难看出，Dockerfile 指令一般格式为 `INSTRUCTION arguments`，而这些指令包括
`FROM`、`MAINTAINER`、`RUN` 等指令，下面就将最为常用的指令介绍下：

<!--sec data-title="FROM 指令" data-id="section1" data-show=true ces-->
格式为： `FROM <image>` 或 `FROM <image[:tag]>`

`FROM` 指令用于指定基础镜像。该指令是 Dockerfile 第一条必须指令，指定要制作的镜像继承至那个镜像。

需要说明的是：可以在 Dockerfile 中写多个 `FROM` 指令来构建复杂的镜像，但是这种方式强烈不推荐。原因在后续作说明。
<!--endsec-->


<!--sec data-title="MAINTAINER 指令" data-id="section2" data-show=true ces-->
格式为： `MAINTAINER <name>`

`MAINTAINER` 指令用于指定维护者信息。
<!--endsec-->

<!--sec data-title="WORKDIR  指令" data-id="section3" data-show=true ces-->
格式为：`WORKDIR  <Dir>`

`WORKDIR` 指令用于设置容器的工作目录，如：`WORKDIR /app` 表示工作目录在容器（镜像）的 `/app` 目录下。
<!--endsec-->

<!--sec data-title="COPY 指令" data-id="section4" data-show=true ces-->
格式为：`COPY <src> <dest>`

`COPY` 指令用于复制主机 `<src>`（为 Dockerfile 所在目录的相对路径）到容器中的 `<dest>`。当使用本地目录为源目录时，推荐使用 `COPY` 指令。
<!--endsec-->


<!--sec data-title="ADD 指令" data-id="section5" data-show=true ces-->
格式为：`COPY <src> <dest>`

`ADD` 指令将复制指定的 `<src>` 到容器中的 `<dest>`。其中 `<src>` 可以是 Dockfile 所在目录的一个相对路径，也可以是一个 URL，**还可以是一个 tar 文件（自动解压为目录）**。
<!--endsec-->


<!--sec data-title="VOLUME 指令" data-id="section6" data-show=true ces-->
格式为：`VOLUME ["/data"]`

`VOLUME` 指令可以创建一个从本地主机或其他容器挂载的挂载点，一般用于存放数据库需要永久保存的数据。

如果和 `host` 共享目录，Dockerfile 中必须先创建一个挂载点，然后在启动容器的时候通过如下命令来设置，其中 `CONTAINERPATH` 就是创建的挂载挂载点。

```
$ docker run -v $HOSTPATH:$CONTAIERPATH
``` 
<!--endsec-->

<!--sec data-title="ENV 指令" data-id="section7" data-show=true ces-->
格式为：`ENV <key> <value>`

`ENV` 指令用于指定一个环境变量，会被后续 `RUN` 指令使用，并在容器运行时保持。
<!--endsec-->


<!--sec data-title="RUN 指令" data-id="section8" data-show=true ces-->
格式为：`RUN <command>` 或 `RUN ["executable","param1","param2" ...]`

`RUN` 指令是用来执行 `shell` 命令的。当解析 Dockerfile 时，遇到 `RUN` 指令，Dockerfile 会将该命令翻译为 `/bin/sh -c "XXX"`，其中
`XXX` 为 `RUN` 指令后的 `shell` 命令。
<!--endsec-->


<!--sec data-title="EXPOSE 指令" data-id="section9" data-show=true ces-->
格式为：`EXPOSE <port>[<port> ...]`

该指令用来将容器的端口暴露出来，也可以通过 `docker run -p` 指令实现和服务器端口的映射。

示例：

```
# 暴露 TCP
EXPOSE 80/tcp

# 暴露 UDP
EXPOSE 80/udp

或者
$ docker run -p 80:80/tcp -p 80:80/udp
```
<!--endsec-->


<!--sec data-title="CMD 指令" data-id="section10" data-show=true ces-->
`CMD` 指令格式有如下三种：

- `CMD ["executable", "param1", "param2" ...]` 使用 `exec` 执行，推荐方式。
- `CMD executable param1 param2 ...` 在 `/bin/sh` 中执行，提供给需要交互的应用。
- `CMD ["param1", "param2" ...]` 提供给 `ENTRYPOINT` 的默认参数。

`CMD` 指令是指定启动容器时执行的命令，每个 Dockerfile 只能有一条 `CMD` 指令。如果指定多条 `CMD` 指令，只有最后一条会被执行。指的说明的是，
如果用户启动容器时指定了运行的命令，则会覆盖掉 `CMD` 指定的命令。具体原因见：[RUN & CMD & Entrypoint](./run-cmd-entrypoint.md)。
<!--endsec-->


<!--sec data-title="ENTRYPOINT 指令" data-id="section11" data-show=true ces-->
`ENTRYPOINT` 指令格式有如下两种：

- `ENTRYPOINT ["executable", "param1", "param2" ...]` 使用 `exec` 执行，推荐方式。
- `ENTRYPOINT executable param1 param2 ...` 在 `/shell` 中执行。

`ENTRYPOINT` 指令与 `CMD` 指令相同都是用于指定启动容器时执行的命令。但是该指令与 `CMD` 指令有些区别，具体见
[RUN & CMD & Entrypoint](./run-cmd-entrypoint.md)。同样的，每个 Dockerfile 只能有一条 `ENTRYPOINT` 指令。如果指定多条
`ENTRYPOINT` 指令，只有最后一条会被执行。
<!--endsec-->

# 镜像构建

上面主要介绍 Dockerfile 中的指令集，在实际应用中需要注意 `CMD` 和 `Entrypoint` 指令集的使用。关于之间的区别你可以参考 [RUN & CMD & Entrypoint](./run-cmd-entrypoint.md)，
本篇是国外作者文章，这里直接进行摘录。因为该文章介绍的特别详细和清晰，所以笔者并没有进行翻译。

以上如果否理解后这里就说下如何基于 Dockerfile 进行构建镜像。Dockerfile 是一个文件，并没有任何后缀名，其实就是使用如下命令进行创建的：

```
$ touch Dockerfile

$ ls
Dockerfile
```

在该文件中即可编写自己的应用，具体见上面示例。下面就说下编写完成后如何进行构建镜像！

Dockerfile 镜像构建指令是：

```
$ docker build .
```

其中 `.` 表示当前目录，执行该命令需要在 Dockerfile 同级目录，即：

```
$ ls
Dockerfile

$ docker build .
```

另外，如果 Dockerfile 在另外一个文件夹中可以指定 `-f` 参数。如 Dockerfile 所在目录是 `/home/docker/`，则执行命令为：

```
$ ls /home/docker/
Dockerfile

$ pwd
/home/data

# 执行命令
$ docker build -f /home/docker/Dockerfile .
```

除此之外，你还可以为构建的镜像使用 `-t` 参数指定标签（也可以理解为名称）：

```
$ docker build -t itumate/myapp .
```

这里使用的标签为 `itumate/myapp`，这是一个标准的标签。即 `itumate` 其实是 DockerHub 的组织名称，`myapp` 是 `itumate` 组织下的一个镜像。
使用该命令构建完成的镜像可以直接推送到远程仓库。

不过，使用该命令构建的没有指定具体版本。docker 会理解它是一个 *dangling* 镜像。所以，这里可以为该镜像指定标签版本好：

```
$ docker build -t itumate/myapp:v1.0.0 .
 or
$ docker build -t itumate/myapp:1.0.0 .
```

版本号可以随意指定，不一定是数字。还有一点需要说明，版本号还可以指定为 `latest` 版本，如下所示。但尽量不要使用该命令，还是使用上面的那种形式比较好：

```
$ docker build -t itumate/myapp:latest .
```

# 总结

本篇只是简单介绍下 Dockerfile 的使用，介绍的指令集也是最常用的。除此之外，还有许多其他指令集。比如创建 `.dockerignore`。

想了解更多指令信息可以参考：[Dockerfile 指令集官网](https://docs.docker.com/engine/reference/builder/)