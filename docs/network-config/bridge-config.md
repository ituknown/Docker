# 单主机容器网络

本篇介绍单主机容器网络的使用（networking for standalone Docker containers）。关于 swarm 集群服务网络配置，点击 [Overlay 网络配置]()，
该主题主要包括三部分，你可以在 Linux、Windows 和 Mac 上进行测试，不过后两个你需要在其他地方运行第二个Docker主机进行测试。

- [默认 bridge 网络](#默认bridge网络) 演示 Docker 如何为你默认配置 bridge 网络。该网络在生产环境下不建议使用。

- [自定义 bridge 网络](#自定义bridge网络) 展示如何创建一个用户自定义的 bridge 网络，并且在同一 Docker 主机上连接容器。该网络是推荐线上
使用的网络类型。

需要注意的是，尽管 Overlay 网络主要用于 swarm 集群服务。不过在 Docker `v17.06` 以及更高的版本允许你在单主机服务上使用。

# 默认 bridge 网络

本示例，你会在同一主机运行两个不同的 `alpine` 容器以及测试了解他们是如何进行通信。在之前，确认 Docker 是否已经运行。

<!--sec data-title="第一步" data-id="section1" data-show=true ces-->
打开命令终端，将当前已有的网络列出来。在此之前即使你在 Docker Daemon（Docker Service 或 Docker Host）创建过网络或者初始化过 `swarm` 
可能会列出更多的网络，你也能看到如下网络。

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
bf92b17490fe        bridge              bridge              local
666c50c30e70        host                host                local
4e6d7e6c3103        none                null                local
```

上面列出的网络除了 `bridge` 外还有 `host` 和 `none`。后面两个虽然没见过，但是用于启动直接连接到 Docker 守护程序主机的网络堆栈的容器，或用于
启动没有网络设备的容器。这里主要演示两个容器同时连接 `bridge` 网络。
<!--endsec-->

<!--sec data-title="第二步" data-id="section2" data-show=true ces-->
使用 `ash` 运行两个 `alpine` 容器，`ash` 是 `alpine` 默认的 `shell` 而不是 `bash`，`-dit` 命令选项意思是在后台以交互式运行容器，并
分配一个 TTY，因此你能看到输入输出信息。启动后会打印容器的id 信息，另外，由于没有使用 `--network` 命令指定网络，因此这两个容器会连接到默认
`bridge` 网络。

```
$ docker run -itd --name alpine1 alpine ash
$ docker run -itd --name alpine2 alpine ash
```

查看容器是否成功运行

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS              PORTS               NAMES
9aae901e5a12        alpine              "ash"               58 seconds ago       Up 58 seconds                           alpine2
20d1d2cc55fb        alpine              "ash"               About a minute ago   Up About a minute                       alpine1
```
<!--endsec-->

<!--sec data-title="第三步" data-id="section3" data-show=true ces-->
检查 `bridge` 网络，看看那些容器连接到了该网络

````
$ docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "bf92b17490fe162cdc0acce5cf566fe010961edf72ed7e1f2f75e0013ce2578a",
        "Created": "2019-01-04T20:53:52.090009766+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "20d1d2cc55fb27c595d406f8dc49175267c1b3016d8b60c562e6f44f514f9c9a": {
                "Name": "alpine1",
                "EndpointID": "b44b1cf0bd253d0f85036509ecb486a1251377b78be5bf610f343509be481154",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            },
            "9aae901e5a12fb5334640bfa8f37df7edbd42feed390c88f7d23773f63e39582": {
                "Name": "alpine2",
                "EndpointID": "0b7f426b93d1855871c04e6038c374741a0875aca385aa399d50af7fc3dc633e",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]
````

可以看到，在顶部列出了 `bridge` 网络信息，包括在 Docker Host 主机上的网关 IP 地址和 `bridge` 网络（`172.17.0.1`）。而在 `Containers`
中，列出了连接该网络的容器和 IP 信息。`alpine1` 的网络地址是 `172.17.0.2`,`alpine2` 的网络地址是 `172.17.0.3`。
<!--endsec-->

<!--sec data-title="第四步" data-id="section4" data-show=true ces-->
两个容器在后台运行，使用 `docker attach` 命令进行其中一个容器，如 `alpine1`。

```
$ docker attach alpine1
/ # 
```

进入容器后的提示符是 `#`，表示进入容器使用的是 `root` 用户。使用 `ip addr show` 命令展示该容器的网络信息。

```
/ # ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
19: eth0@if20: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

第一个接口是环回设备，暂时忽略。在第二个接口中列出的 ip 地址是 `172.17.0.2`，是不是与之前列出的地址相同？
<!--endsec-->

<!--sec data-title="第五步" data-id="section5" data-show=true ces-->
在 `alpine1` 容器中 `ping` 看看是否能连接到外网，如 `google`。哦，如果不能享受自由的话就使用 `baidu` 也行。在 `ping` 中使用 `-c` 选
项表示 `ping` 次数。

```
# ping -c 3 baidu.com
PING baidu.com (123.125.115.110): 56 data bytes
64 bytes from 123.125.115.110: seq=0 ttl=50 time=29.029 ms
64 bytes from 123.125.115.110: seq=1 ttl=50 time=28.695 ms
64 bytes from 123.125.115.110: seq=2 ttl=50 time=28.495 ms

--- baidu.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 28.495/28.739/29.029 ms
```

看的出来，能连接到外网。
<!--endsec-->

<!--sec data-title="第六步" data-id="section6" data-show=true ces-->
现在是试试 `ping` 下第二个容器，通过 IP 地址 `172.17.0.3`：

```
# ping -c 3 172.17.0.3
PING 172.17.0.3 (172.17.0.3): 56 data bytes
64 bytes from 172.17.0.3: seq=0 ttl=64 time=0.120 ms
64 bytes from 172.17.0.3: seq=1 ttl=64 time=0.079 ms
64 bytes from 172.17.0.3: seq=2 ttl=64 time=0.083 ms

--- 172.17.0.3 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.079/0.094/0.120 ms
```

`ping` 成功了，再试试使用别名 `alpine2` `ping` 试试，会失败！

```
# ping -c 3 alpine2
ping: bad address 'alpine2'
```
<!--endsec-->

<!--sec data-title="第七步" data-id="section7" data-show=true ces-->
使用命令 `ctrl + p + q` 组合命令退出容器（但不停止容器）。当然，你也可以再次进入 `alpine2` 容器重复之前的步骤。不出意外，你将会得到同样的
结果。
<!--endsec-->

<!--sec data-title="第八步" data-id="section8" data-show=true ces-->
停止、删除容器

```
$ docker stop alpine1 alpine2
$ docker rm alpine1 alpine2
```

> **[success] 注意**
>
> 一定要记住，默认的 `bridge` 网络不推荐在线上使用，你应该使用自定义的 `bridge` 网络。
<!--endsec-->

# 自定义 bridge 网络

在本示例，将继续使用 `alpine` 容器进行演示，不过使用自定义的 `alpine-net` 网络。这些容器不在连接默认的网络，笔者启动三个容器进行连接 
`alpine-net` 网络，在第四个容器进行连接默认的 `bridge` 网络。不过，在三个网络会同时连接默认的 `bridge` 网络。

<!--sec data-title="第一步" data-id="section9" data-show=true ces-->
创建 `alpine-net` 网络，你可以不使用 `--driver bridge` 参数，不过这里进行展示如何指定。

```
$ docker network create --driver bridge alpine-net
```
<!--endsec-->

<!--sec data-title="第二步" data-id="section10" data-show=true ces-->
列出 Docker 主机网络

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
09e240b089d0        alpine-net          bridge              local
bf92b17490fe        bridge              bridge              local
666c50c30e70        host                host                local
4e6d7e6c3103        none                null                local
```

检查 `alpine-net` 网络。看下该网络当前是否有容器连接到该网络

```
$ docker network inspect alpine-net
[
    {
        "Name": "alpine-net",
        "Id": "09e240b089d0183571d618bfc5286820f4c92d682e503cea26330bf8b727487f",
        "Created": "2019-01-05T15:27:16.949380969+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "Gateway": "172.19.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

当前网络的网管地址是 `172.19.0.1`，在之前的默认网管地址则是 `172.17.0.1`，不过地址是随机分配的，在另外一个系统上可能会不一样。
<!--endsec-->

<!--sec data-title="第三步" data-id="section11" data-show=true ces-->
创建四个容器，并使用 `--network` 进行指定网络。在容器运行时只能连接一个网络。因此，如果一个容器要连接多个网络则要使用 `docker network connect`
在容器运行以后进行连接。

```
$ docker run -itd --name alpine1 --network alpine-net alpine ash
$ docker run -itd --name alpine2 --network alpine-net alpine ash
$ docker run -itd --name alpine3 alpine ash
$ docker run -itd --name alpine4 --network alpine-net alpine ash
$ docker network connect bridge alpine4
```

查看容器是否运行成功

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
b0d55561abdf        alpine              "ash"               2 seconds ago       Up 2 seconds                            alpine1
0950fb3c192a        alpine              "ash"               10 seconds ago      Up 10 seconds                           alpine4
aded48f7b43c        alpine              "ash"               17 seconds ago      Up 16 seconds                           alpine3
da188bdcee3b        alpine              "ash"               17 seconds ago      Up 17 seconds                           alpine2
```
<!--endsec-->

<!--sec data-title="第四步" data-id="section12" data-show=true ces-->
再次检查默认的 `bridge` 网络和自定义的 `alpine-net` 网络：

```
# docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "bf92b17490fe162cdc0acce5cf566fe010961edf72ed7e1f2f75e0013ce2578a",
        "Created": "2019-01-04T20:53:52.090009766+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "0950fb3c192a51d46d6235d753b5a1621cbe79d110089a892e826899b3f6b9ac": {
                "Name": "alpine4",
                "EndpointID": "aaca6dabbd9c159ac00e84cdcf1d9bc55bfb0b74840b1cdc2e9eb1093c6bd088",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            },
            "aded48f7b43c117bfe758f1b13ca315418cdde8567cac6a8408b291a307989d7": {
                "Name": "alpine3",
                "EndpointID": "082752e5ab98258c497ce08b0e85c219b37c2992de0af094be06f29425d76ec3",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]
```

容器 `alpine3` 和 `alpine4` 连接到的默认的 `bridge` 网络。

```
$ docker network inspect alpine-net
[
    {
        "Name": "alpine-net",
        "Id": "09e240b089d0183571d618bfc5286820f4c92d682e503cea26330bf8b727487f",
        "Created": "2019-01-05T15:27:16.949380969+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "Gateway": "172.19.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "0950fb3c192a51d46d6235d753b5a1621cbe79d110089a892e826899b3f6b9ac": {
                "Name": "alpine4",
                "EndpointID": "b961f68ba91823134c1546e422e9f3016d32d4be1a706ecb84aa8c8ee2d22831",
                "MacAddress": "02:42:ac:13:00:03",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            },
            "b0d55561abdf28fbf4c2e6fbf9cfc41cac247140974853b2ae58015a759fb846": {
                "Name": "alpine1",
                "EndpointID": "3d39b7dd9db833a8bb4f1be4c38e40ccdae438689de4404fe538b8c0ed15ba6a",
                "MacAddress": "02:42:ac:13:00:04",
                "IPv4Address": "172.19.0.4/16",
                "IPv6Address": ""
            },
            "da188bdcee3bac86919c833c2010242128c247f534ee1e99b955b2863edf184f": {
                "Name": "alpine2",
                "EndpointID": "7119ba3871670d08e147b9870f53dd3ee25c58ec53df085885599f9d24bd31fa",
                "MacAddress": "02:42:ac:13:00:02",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

容器 `alpine1`、`alpine2` 和 `alpine4` 连接到了 `alpine-net` 网络。
<!--endsec-->

<!--sec data-title="第五步" data-id="section13" data-show=true ces-->
在自定义的网络中，如 `alpine-net`。容器不仅能通过 IP 进行通信，而且同时能通过容器的别名进行通信。这种能力类同 `Spring Cloud` 的 `Eureka`，
被称为 **服务注册发现（automatic service discovery）**。现在使用 `docker attach` 命令进入容器 `alpine1` 进行测试，`alpine1`应该能够
将`alpine2`和`alpine4`（以及`alpine1`本身）解析为IP地址。

```
$ docker attach alpine1

# ping -c 3 alpine2

PING alpine2 (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.135 ms
64 bytes from 172.19.0.2: seq=1 ttl=64 time=0.078 ms
64 bytes from 172.19.0.2: seq=2 ttl=64 time=0.083 ms

--- alpine2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.078/0.098/0.135 ms

# ping -c 3 alpine4

PING alpine4 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.140 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.080 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.123 ms

--- alpine4 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.080/0.114/0.140 ms

# ping -c 3 alpine1

PING alpine1 (172.19.0.4): 56 data bytes
64 bytes from 172.19.0.4: seq=0 ttl=64 time=0.035 ms
64 bytes from 172.19.0.4: seq=1 ttl=64 time=0.054 ms
64 bytes from 172.19.0.4: seq=2 ttl=64 time=0.127 ms

--- alpine1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.035/0.072/0.127 ms
```
<!--endsec-->

<!--sec data-title="第六步" data-id="section14" data-show=true ces-->
在 `alpine1` 中，不同连接到 `alpine3`。因为他不在 `alpine-net` 网络中。

```
# ping -c 3 alpine3
ping: bad address 'alpine3'
```

不仅仅不能通过容器别名进行通信。而且也不能通过 `alpine3` 的 IP（`172.17.0.2`）进行通信。

```
# ping -c 3 172.17.0.2
PING 172.17.0.2 (172.17.0.2): 56 data bytes

--- 172.17.0.2 ping statistics ---
3 packets transmitted, 0 packets received, 100% packet loss
```

使用 `ctrl + p +q` 组合键退出 `alpine1` 容器。
<!--endsec-->

<!--sec data-title="第七步" data-id="section15" data-show=true ces-->
还记得 `alpine4` 不仅仅连接到了自定义的 `alpine-net` 网络。同时还连接到了默认的 `bridge` 网络。它应该能与所有的容器进行通信。然而，在与
`alpine3` 进行通信时依然不能通过别名，只能通过 IP 地址。

```
$ docker attach alpine4

# ping -c 3 alpine1

PING alpine1 (172.19.0.4): 56 data bytes
64 bytes from 172.19.0.4: seq=0 ttl=64 time=0.096 ms
64 bytes from 172.19.0.4: seq=1 ttl=64 time=0.081 ms
64 bytes from 172.19.0.4: seq=2 ttl=64 time=0.080 ms

--- alpine1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.080/0.085/0.096 ms

# ping -c 3 alpine2

PING alpine2 (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.161 ms
64 bytes from 172.19.0.2: seq=1 ttl=64 time=0.237 ms
64 bytes from 172.19.0.2: seq=2 ttl=64 time=0.079 ms

--- alpine2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.079/0.159/0.237 ms

# ping -c 3 alpine3
ping: bad address 'alpine3'

# ping -c 3 172.17.0.2

PING 172.17.0.2 (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: seq=0 ttl=64 time=0.155 ms
64 bytes from 172.17.0.2: seq=1 ttl=64 time=0.352 ms
64 bytes from 172.17.0.2: seq=2 ttl=64 time=0.251 ms

--- 172.17.0.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.155/0.252/0.352 ms
```
<!--endsec-->

<!--sec data-title="第八步" data-id="section16" data-show=true ces-->
最后再测试一次。确定容器能连接到外网，就以 `baidu` 为例。当前已经在 `alpine4` 容器中了，就以该容器开始。然后再进入容器 `alpine3` ...

```
# ping -c 3 baidu.com

PING baidu.com (220.181.57.216): 56 data bytes
64 bytes from 220.181.57.216: seq=0 ttl=52 time=27.241 ms
64 bytes from 220.181.57.216: seq=1 ttl=52 time=27.195 ms
64 bytes from 220.181.57.216: seq=2 ttl=52 time=27.819 ms

--- baidu.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 27.195/27.418/27.819 ms

CTRL + P + Q

$ docker attach alpine3

# ping -c 3 baidu.com
PING baidu.com (220.181.57.216): 56 data bytes
64 bytes from 220.181.57.216: seq=0 ttl=52 time=27.193 ms
64 bytes from 220.181.57.216: seq=1 ttl=52 time=27.931 ms
64 bytes from 220.181.57.216: seq=2 ttl=52 time=27.300 ms

--- baidu.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 27.193/27.474/27.931 ms

CTRL + P + Q

$ docker attach alpine2

# ping -c 3 baidu.com
PING baidu.com (123.125.115.110): 56 data bytes
64 bytes from 123.125.115.110: seq=0 ttl=50 time=29.049 ms
64 bytes from 123.125.115.110: seq=1 ttl=50 time=28.564 ms
64 bytes from 123.125.115.110: seq=2 ttl=50 time=28.852 ms

--- baidu.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 28.564/28.821/29.049 ms

CTRL + P + Q

$ docker attach alpine1

# ping -c 3 baidu.com
PING baidu.com (220.181.57.216): 56 data bytes
64 bytes from 220.181.57.216: seq=0 ttl=52 time=27.465 ms
64 bytes from 220.181.57.216: seq=1 ttl=52 time=27.288 ms
64 bytes from 220.181.57.216: seq=2 ttl=52 time=27.610 ms

--- baidu.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 27.288/27.454/27.610 ms
```
<!--endsec-->

<!--sec data-title="第九步" data-id="section17" data-show=true ces-->
停止、删除所有容器并删除 `alpine-net` 自定义 `bridge` 网络。

```
$ docker container stop alpine1 alpine2 alpine3 alpine4
$ docker container rm alpine1 alpine2 alpine3 alpine4
$ docker network rm alpine-net
```
<!--endsec-->