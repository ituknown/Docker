# 前言

在网络方面，`bridge` 网络是在网络段之间转发流量的链路层设备。`bridge` 可以是硬件设备或在主机内核中运行的软件设备。

在 Docker 中，`bridge` 网络使用软件桥接器，该软件桥接器允许连接到同一 `bridge` 网络的容器进行通信，同时提供与未连接到该 `bridge` 网络的容
器的隔离。

Docker桥驱动程序会自动在主机中安装规则，以便不同网桥上的容器无法直接相互通信。

`bridge` 网络应用于在同一主机的多个容器之间的通信。而在不同主机之间的容器的通信可以使用 `overlay` 网络。

当运行 Docekr 时，默认的 `bridge` 会自动被创建（默认 `bridge` 网路的名称是 `bridge`）。在运行容器时不指定网络，那么该容器就会连接到该网络。
**自定义的 `bridge` 网络优于默认的 `bridge` 网络**

# 自定义 bridge 与默认 bridge

- 自定义的 bridgea 网络可以在容器化应用程序之间提供更好的隔离和互通性。

多个容器连接到同一自定义 `bridge` 网络时，容器之间会自动暴露全部的端口，并且不会向外部暴露端口。这可以使容器化应用程序之间通信更简单，而不会意外
的向外部暴露端口。

试想一下这个场景：一个拥有 web 前端后数据库后端的应用。外部能直接访问 web 端，但只有后端本身需要访问数据库主机和端口。使用自定义的 bridge，仅仅
web 端需要向外部暴露端口，2而数据后端不需要暴露任何端口。因为 web 前端可以使用自定义的 bridge 网络连接到数据后端。

但是如果直接使用默认的 bridge。你需要将 web 前端与数据后端的端口都要暴露出来，你需要使用 `-p` 或 `-publish` 选项。这意味着Docker主机需要通
过其他方式阻止对数据库端口的访问。

- 自定义的 bridge 提供多个容器之间的自动 DNS 解析。

默认 bridge 网络上的容器只能通过 IP 地址实现互相访问。除非你使用 `--link` 选项，不过该选项属于即将废弃的选项。使用自定义的 bridge 网络，容器
通过名称或者别名实现解析。

继续使用之前的 web 前端与 db 后端为例。前端容器名称为 `web`，后端容器名称为 `db`。无论运行应用程序堆栈的 Docker 主机是什么， web 容器都可以
连接到 db 的 db 容器（有点拗口？意思就是说，web 容器能直接通过 `db` 名称实现与 db 容器之间的通信）。

如果使用默认的 bridge，你需要使用 `--link` 选项实现之间的通信。这些链接需要在两个方向上创建，因此这对于需要通信的两个以上容器而言变得更复杂。
另外，你也可以通过修改 `/etc/hosts` 文件实现通信，不过这可能会导致难以排查的 bug。

- 容器可以在运行中与用户定义的网络连接或分离。 

在容器的运行生命周期中，你可以直接从自定义的 bridge 网络连接或断开连接。如果使用自定义的 bridge 网络，你需要先停止容器然后再通过选择其他的网络
进行重新创建它。

- 自定义 bridge 是可配置的。

如果一个容器连接在默认的 bridge 上，你可以进行重新配置它，不过这会在连接该网络的所有容器中生效。此外，配置默认 bridge 网络发生在Docker本身之外，
并且需要重新启动Docker。

自定义的 bridge 创建和使用都可以使用 `docker network create` 命令。如果不同的应用组之间有不同的网络配置需求，你可以向创建自定义网络一样配置
它。

- 共享变量。原本，可以直接使用 `--link` 选项实现容器之间的变量共享，不过这不能再自定义 bridge 网络中使用。在自定义网络中共享变量可以使用下面几种方式：
  - 使用 `Docker volume` 多个容器可以挂载包含共享信息的文件或目录。
  - 多个容器可以使用 `docker-compose` 实现同时启动，而且 `compose` 文件可以定义共享变量。
  - 使用 swarm 服务代替独立容器，并利用共享的密匙和配置。
  
连接到同一自定义的 bridge 的容器有效地将所有端口相互暴露。要使端口可以访问不同网络上的容器或非 Docker主机，必须使用 `-p` 或 `--publish` 标
志发布该端口。

# 管理自定义 bridge

对于自定义的 bridge 网络，可以使用 `docker network create` 命令进行创建

```
$ docker network create my-net
```

你可以指定子网络，IP地址范围，网关和其他选项。你可以使用 `docker network create --help` 命令查看全部选项说明。

```
$ docker network create --help

Usage:	docker network create [OPTIONS] NETWORK

Create a network

Options:
      --attachable           Enable manual container attachment
      --aux-address map      Auxiliary IPv4 or IPv6 addresses used by Network driver (default map[])
      --config-from string   The network from which copying the configuration
      --config-only          Create a configuration only network
  -d, --driver string        Driver to manage the Network (default "bridge")
      --gateway strings      IPv4 or IPv6 Gateway for the master subnet
      --ingress              Create swarm routing-mesh network
      --internal             Restrict external access to the network
      --ip-range strings     Allocate container ip from a sub-range
      --ipam-driver string   IP Address Management Driver (default "default")
      --ipam-opt map         Set IPAM driver specific options (default map[])
      --ipv6                 Enable IPv6 networking
      --label list           Set metadata on a network
  -o, --opt map              Set driver specific options (default map[])
      --scope string         Control the network's scope
      --subnet strings       Subnet in CIDR format that represents a network segment

```

使用 `docker network rm` 命令可以删除自定义的 bridge 网络，如果有容器正在连接该网络要先将容器从该网络断开后再删除。

```
$ docker network rm my-net
```

# 容器连接自定义网络

当创建一个新的容器时，可以使用 `--network` 选择指定一个网络。下面示例时一个 `Nginx` 容器连接到 `my-net` 网络。它可以将 80 端口发不发到 Docker
注意的 8080 端口，所以外部客户端可以访问该端口。连接到 `my-net` 网络的任何其他容器都可以访问 `my-nginx` 容器上的所有端口，反之亦然。

```
$ docker create --name my-nginx \
  --network my-net \
  --publish 8080:80 \
  nginx:latest
```

一个运行中的容器想要连接自定义网络，可以使用 `docker network connect` 命令。下面命令是一个正在运行中的 `my-nginx` 容器连接到已存在的 `my-net`
 网络。
 
 ```
 $ docker network connect my-net my-nginx
 ```
 
 # 容器断开自定义 bridge 网络
 
 要一个正在运行中的容器从自定义的网络中断开，可以使用 `docker network disconnect` 命令。如下：
 
 ```
 $ docker network disconnect my-net my-nginx
 ```