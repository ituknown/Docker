# 前言

本主题主要说明在 `swarm` 服务集群中的 `overlay` 网络的使用。关于单主机容器网络配置见 [bridge 网络配置](./bridge-net-config.md)。

本节主要包括四个部分。

- [默认 overlay 网络]() 展示当初始化或加入一个 `swarm` 集群后 Docker 如何自动配置默认的 `overlay` 网络。该 `overlay` 网络不建议在
线上使用。

- [自定义 overlay 网络]() 展示如何创建一个 `overlay` 及服务如何加入该网络。推荐在线上使用自定义的 `overlay` 网络。

- [在独立容器中使用 overlay 网络]() 展示如何使用 `overlay` 网络在不同 Docker 守护程序（即 Docker 服务器）上的独立容器之间进行通信。

# 准备工作

本节需要准备3台主机或者虚拟机也可以。Docker 版本最低要求是 `v17.03`。三台主机中一个管理节点、两个工作节点，当然管理节点本身也是一个工作节点。

- 管理节点：`192.168.1.9`
- 工作节点1：`192.168.1.10`
- 工作节点2：`192.168.1.12`

# 默认 overlay 网络

在之前先看一个三台主机的网络：

管理节点：
```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
bf92b17490fe        bridge              bridge              local
666c50c30e70        host                host                local
4e6d7e6c3103        none                null                local
```

另外，两个工作节点中的网络与管理节点也是一样的，这里只是列出来号进行后续比较。

## 创建 swarm

- 在管理节点上，初始化 `swarm`。如果你的主机只有一个网络接口，可以使用 `--advertise-addr` 进行指定 IP 地址：

```
$ docker swarm init --advertise-addr=<IP-ADDRESS-OF-MANAGER>
```

```
$ docker swarm init --advertise-addr=192.168.1.9
Swarm initialized: current node (4ccar9aqotyetbi5sde86q5z5) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-2wnbo5bdf4rs92nde2hb2qrh5gjb1rry46bpkh7rkrr4nu61do-c71ufntkr69tf0h5fmnb2ffpe 192.168.1.9:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

- 在管理节点初始化完成后，加入工作节点。同样的，如果工作节点没有也只有一个网络接口，需要使用 `--advertise-addr` 参数进行进行指定 IP 地址：

```
$ docker swarm join --token <TOKEN> \
  --advertise-addr <IP-ADDRESS-OF-WORKER-1> \
  <IP-ADDRESS-OF-MANAGER>:2377
```

在工作1节点加入 `swarm`：

```
$ docker swarm join --token SWMTKN-1-2wnbo5bdf4rs92nde2hb2qrh5gjb1rry46bpkh7rkrr4nu61do-c71ufntkr69tf0h5fmnb2ffpe 192.168.1.9:2377 --advertise-addr=192.168.1.10

This node joined a swarm as a worker.
```

- 在工作2节点同样加入 `swarm` 后，在管理节点上列出所有的节点，该命令只能在管理节点上运行。

```
$ docker node ls
ID                            HOSTNAME                STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
4f6g7ym3ph4ndc04z93k7zi1w     192.168.1.10            Ready               Active                                  18.09.0
m8hmrxxdnazrjk1e9wkerqtkq *   192.168.1.9             Ready               Active              Leader              18.09.0
vzi7hibq5mfp5a9bktwiop4cs     192.168.1.12            Ready               Active                                  18.09.0
```

另外，也可以使用 `--filter` 标识进行过滤

```
$ docker node ls --filter role=manager
ID                            HOSTNAME                STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
4ccar9aqotyetbi5sde86q5z5 *   192.168.1.9             Ready               Active              Leader              18.09.0

$ docker node ls --filter role=worker
ID                            HOSTNAME                STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
4f6g7ym3ph4ndc04z93k7zi1w     192.168.1.10            Ready               Active                                  18.09.0
vzi7hibq5mfp5a9bktwiop4cs     192.168.1.12            Ready               Active                                  18.09.0
```

- 在管理节点和工作节点分别列出网络，看到相比之前分别多了一个属于 `overlay` 名为 `ingress` 的网络和一个属于 `bridge` 名为 `docker_gwbridge` 的网络。

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
bf92b17490fe        bridge              bridge              local
6480b7bc0dd3        docker_gwbridge     bridge              local
666c50c30e70        host                host                local
344gz56pl2l3        ingress             overlay             swarm
4e6d7e6c3103        none                null                local
```

`docker_gwbridge` 网络将 `ingress` 网络连接到 Docker主机的网络接口，以便在管理节点与工作节点之间进行通信。如果你创建一个 `swarm` 集群服务，
而没有指定网络，将会默认连接到 `ingress` 网络。因此建议为可以协同工作的每个应用程序或应用程序组使用单独的 `overlay` 网络。

## 创建服务

- 在管理节点上，创建一个名为 `nginx-net` 的 `overlay` 网络。

```
$ docker network create -d overlay nginx-net
```

该命令不需要再工作节点上进行再次创建，在管理节点上创建一个网络后，当在节点上启动服务后工作节点会自动的创建该网络。

在管理节点上将网络列出，看是否有名为 `nginx-net` 的 `overlay` 类型网络。

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
bf92b17490fe        bridge              bridge              local
6480b7bc0dd3        docker_gwbridge     bridge              local
666c50c30e70        host                host                local
344gz56pl2l3        ingress             overlay             swarm
lknuq2ejwia6        nginx-net           overlay             swarm
4e6d7e6c3103        none                null                local
```

- 在管理节点上，创建一个 `Nginx` 服务的五个实例，向外部暴露 `80` 端口，这样所有服务任务容器都可以相互通信而无需打开任何端口。

```
$ docker service create \
  --name my-nginx \
  --publish target=80,published=80 \
  --replicas=5 \
  --network nginx-net \
  nginx
  
zgekieqpk946o00sonf13g1g6
overall progress: 5 out of 5 tasks 
1/5: running   [==================================================>] 
2/5: running   [==================================================>] 
3/5: running   [==================================================>] 
4/5: running   [==================================================>] 
5/5: running   [==================================================>] 
verify: Service converged
```

当你没有使用 `--publish` 标识进行指定模式时，会默认使用 `ingress` 模式发布。意思是，当你在管理节点或者在两个工作节点访问 `80` 端口时，你将会
在5个服务任务之一上连接到端口80，即使你浏览到的节点上当前没有任何任务正在运行。如果你想要使用 `host` 模式进行发布，你可以将 `mode=host` 加入
到 `--publish` 进行输出。不过，在这种情况下，你还需要使用 `--mode global` 而不是 `--replicas = 5`，因为只有一个服务任务可以绑定给定节点
上的给定端口。

- 在管理节点运行 `docker service ls` 命令进行查看服务是否起来

```
$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
zgekieqpk946        my-nginx            replicated          5/5                 nginx:latest        *:80->80/tcp
```

另外，之前说。在管理节点创建 `overlay` 网络后，不需要再在工作节点上再次创建，因为当运行服务后会在工作节点上自动创建，现在在工作节点上查看下 
`nginx-net` 网络是否自动创建：

```
# 192.168.1.10 工作节点
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
8f29fbe91663        bridge              bridge              local
b2da9e66dfb0        docker_gwbridge     bridge              local
1006fa4fcdc1        host                host                local
344gz56pl2l3        ingress             overlay             swarm
lknuq2ejwia6        nginx-net           overlay             swarm
ad1bf137cf18        none                null                local
```

看到，以自动创建。

- 在管理、工作1和工作2节点上检查 `nginx-net` 网络（注意，不需要再工作节点再次创建该网络，因为 Docker 会自动为你创建），输出会比较长。最需要
注意的时 `containers` 和 `peers` 部分。`containers` 部分列出所有从该主机连接到 `overlay` 网络的服务任务（或独立容器）。

**管理节点**
```
$ docker network inspect nginx-net
[
    {
        "Name": "nginx-net",
        "Id": "lknuq2ejwia6l3x8yjulrn5zu",
        "Created": "2019-01-06T15:30:05.985792674+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.0.0/24",
                    "Gateway": "10.0.0.1"
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
            "68b867162f66dab0afc3f79ef7f8c6074744d01e6d03e4452d94e3be59fc958d": {
                "Name": "my-nginx.2.yb03otxoqryiylq6pf77ytlig",
                "EndpointID": "04155448b30f6bd8bb8d57c8c2bbde97f3c3b153995c95575ea784cec1d3ade2",
                "MacAddress": "02:42:0a:00:00:04",
                "IPv4Address": "10.0.0.4/24",
                "IPv6Address": ""
            },
            "lb-nginx-net": {
                "Name": "nginx-net-endpoint",
                "EndpointID": "9cdc6b75bb7195bc5583b3dd2f542127d4e404ba68d28363cad69c37a6caea7e",
                "MacAddress": "02:42:0a:00:00:0a",
                "IPv4Address": "10.0.0.10/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "a4037138043d",
                "IP": "192.168.1.9"
            },
            {
                "Name": "746de4a0435c",
                "IP": "192.168.1.12"
            },
            {
                "Name": "b4d8838fb56f",
                "IP": "192.168.1.10"
            }
        ]
    }
]
```

**工作1节点**
```
$ docker network inspect nginx-net
[
    {
        "Name": "nginx-net",
        "Id": "lknuq2ejwia6l3x8yjulrn5zu",
        "Created": "2019-01-06T15:30:05.988961101+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.0.0/24",
                    "Gateway": "10.0.0.1"
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
            "2ee96a8062c5fb38149040b4df044a9c8db3083ab9fb41cc2dc5b0dcc5e8cf47": {
                "Name": "my-nginx.5.lf2qcvi39r28yaw88w3ohuoz7",
                "EndpointID": "f688acbf0810b2a064958046eca99b37c82041929b3143dabdc2d599c9d48497",
                "MacAddress": "02:42:0a:00:00:07",
                "IPv4Address": "10.0.0.7/24",
                "IPv6Address": ""
            },
            "cc474c0ea3235ef36f490953ad9f5a82b924cf9ad0896f0663c901c1f5a7f2cb": {
                "Name": "my-nginx.3.jo2s51nhqrlkx59sqw1yo26ux",
                "EndpointID": "7ccdf91c7d0ffeafb391d9e06dd86e819df04c64037426d730524fddd2bb6ff0",
                "MacAddress": "02:42:0a:00:00:05",
                "IPv4Address": "10.0.0.5/24",
                "IPv6Address": ""
            },
            "lb-nginx-net": {
                "Name": "nginx-net-endpoint",
                "EndpointID": "be82c7735413e3b8af331d811014d58b6e94fedb970c0c9faa8629bc32fe6b48",
                "MacAddress": "02:42:0a:00:00:08",
                "IPv4Address": "10.0.0.8/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "b4d8838fb56f",
                "IP": "192.168.1.10"
            },
            {
                "Name": "a4037138043d",
                "IP": "192.168.1.9"
            },
            {
                "Name": "746de4a0435c",
                "IP": "192.168.1.12"
            }
        ]
    }
]
```

**工作2节点**
```
$ docker network inspect nginx-net
[
    {
        "Name": "nginx-net",
        "Id": "lknuq2ejwia6l3x8yjulrn5zu",
        "Created": "2019-01-06T15:30:05.989094312+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.0.0/24",
                    "Gateway": "10.0.0.1"
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
            "5c26f1464c684c33b8c94a923919ec3fc80f0da98def214ce261bbf32a34eeed": {
                "Name": "my-nginx.1.uoim3lrc76ipbxvw07yzq0euk",
                "EndpointID": "ce2133c8c7c9a7b7a1b6a7374a9c3c6a613a0742753a94aebe88404727acbedc",
                "MacAddress": "02:42:0a:00:00:03",
                "IPv4Address": "10.0.0.3/24",
                "IPv6Address": ""
            },
            "fe198907032c11ad5488921d222d87c7305d7ab3bb885668c69ac88d1652df51": {
                "Name": "my-nginx.4.5p03u0z7n2b3qqlmrx4dgb5ls",
                "EndpointID": "7898c659a2e8217ae4f346bc93497a194493f8a5122dc89282d57df8afa290bb",
                "MacAddress": "02:42:0a:00:00:06",
                "IPv4Address": "10.0.0.6/24",
                "IPv6Address": ""
            },
            "lb-nginx-net": {
                "Name": "nginx-net-endpoint",
                "EndpointID": "d39c4b74a39c8c45d44c071c1836fabf2ee2c3162226e5655fa8470898b4caa0",
                "MacAddress": "02:42:0a:00:00:09",
                "IPv4Address": "10.0.0.9/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "746de4a0435c",
                "IP": "192.168.1.12"
            },
            {
                "Name": "a4037138043d",
                "IP": "192.168.1.9"
            },
            {
                "Name": "b4d8838fb56f",
                "IP": "192.168.1.10"
            }
        ]
    }
]
```

- 在管理节点上使用 `docker service inspect my-nginx` 命令检查服务，需要注意有关服务的端口和端点信息

```
$ docker service inspect my-nginx
[
    {
        "ID": "zgekieqpk946o00sonf13g1g6",
        "Version": {
            "Index": 24
        },
        "CreatedAt": "2019-01-06T07:30:05.803235091Z",
        "UpdatedAt": "2019-01-06T07:30:05.804887452Z",
        "Spec": {
            "Name": "my-nginx",
            "Labels": {},
            "TaskTemplate": {
                "ContainerSpec": {
                    "Image": "nginx:latest@sha256:b543f6d0983fbc25b9874e22f4fe257a567111da96fd1d8f1b44315f1236398c",
                    "Init": false,
                    "StopGracePeriod": 10000000000,
                    "DNSConfig": {},
                    "Isolation": "default"
                },
                "Resources": {
                    "Limits": {},
                    "Reservations": {}
                },
                "RestartPolicy": {
                    "Condition": "any",
                    "Delay": 5000000000,
                    "MaxAttempts": 0
                },
                "Placement": {
                    "Platforms": [
                        {
                            "Architecture": "amd64",
                            "OS": "linux"
                        },
                        {
                            "OS": "linux"
                        },
                        {
                            "Architecture": "arm64",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "386",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "ppc64le",
                            "OS": "linux"
                        },
                        {
                            "Architecture": "s390x",
                            "OS": "linux"
                        }
                    ]
                },
                "Networks": [
                    {
                        "Target": "lknuq2ejwia6l3x8yjulrn5zu"
                    }
                ],
                "ForceUpdate": 0,
                "Runtime": "container"
            },
            "Mode": {
                "Replicated": {
                    "Replicas": 5
                }
            },
            "UpdateConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "RollbackConfig": {
                "Parallelism": 1,
                "FailureAction": "pause",
                "Monitor": 5000000000,
                "MaxFailureRatio": 0,
                "Order": "stop-first"
            },
            "EndpointSpec": {
                "Mode": "vip",
                "Ports": [
                    {
                        "Protocol": "tcp",
                        "TargetPort": 80,
                        "PublishedPort": 80,
                        "PublishMode": "ingress"
                    }
                ]
            }
        },
        "Endpoint": {
            "Spec": {
                "Mode": "vip",
                "Ports": [
                    {
                        "Protocol": "tcp",
                        "TargetPort": 80,
                        "PublishedPort": 80,
                        "PublishMode": "ingress"
                    }
                ]
            },
            "Ports": [
                {
                    "Protocol": "tcp",
                    "TargetPort": 80,
                    "PublishedPort": 80,
                    "PublishMode": "ingress"
                }
            ],
            "VirtualIPs": [
                {
                    "NetworkID": "344gz56pl2l3rhpxu9ykibwb1",
                    "Addr": "10.255.0.5/16"
                },
                {
                    "NetworkID": "lknuq2ejwia6l3x8yjulrn5zu",
                    "Addr": "10.0.0.2/24"
                }
            ]
        }
    }
]
```

- 在管理节点上创建 `nginx-net-2` `overlay` 网络，并代替服务的 `nginx-net` 网络

```
$ docker network create -d overlay nginx-net-2
lg6urfk7yt2856xvlj565dho0

$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
bf92b17490fe        bridge              bridge              local
6480b7bc0dd3        docker_gwbridge     bridge              local
666c50c30e70        host                host                local
344gz56pl2l3        ingress             overlay             swarm
lknuq2ejwia6        nginx-net           overlay             swarm
lg6urfk7yt28        nginx-net-2         overlay             swarm
4e6d7e6c3103        none                null                local

$ docker service update \
  --network-add nginx-net-2 \
  --network-rm nginx-net \
  my-nginx
  
my-nginx
overall progress: 5 out of 5 tasks 
1/5: running   [==================================================>] 
2/5: running   [==================================================>] 
3/5: running   [==================================================>] 
4/5: running   [==================================================>] 
5/5: running   [==================================================>] 
verify: Service converged 
```

- 运行 `docker service ls` 命令验证服务是否已经被更新以及任务是否已被重新部署。运行 `docker network inspect nginx-net` 命令验证当前已
经没有容器连接该网络，运行同样的命令检查 `nginx-net-2` 网络看是不是所有的容器都要已经连接到了该网络。

```
$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
zgekieqpk946        my-nginx            replicated          5/5                 nginx:latest        *:80->80/tcp

$ docker network inspect nginx-net
[
    {
        "Name": "nginx-net",
        "Id": "lknuq2ejwia6l3x8yjulrn5zu",
        "Created": "2019-01-06T15:30:05.985792674+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.0.0/24",
                    "Gateway": "10.0.0.1"
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
            "lb-nginx-net": {
                "Name": "nginx-net-endpoint",
                "EndpointID": "9cdc6b75bb7195bc5583b3dd2f542127d4e404ba68d28363cad69c37a6caea7e",
                "MacAddress": "02:42:0a:00:00:0a",
                "IPv4Address": "10.0.0.10/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4097"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "a4037138043d",
                "IP": "192.168.1.9"
            },
            {
                "Name": "746de4a0435c",
                "IP": "192.168.1.12"
            },
            {
                "Name": "b4d8838fb56f",
                "IP": "192.168.1.10"
            }
        ]
    }
]

$ docker network inspect nginx-net-2
[
    {
        "Name": "nginx-net-2",
        "Id": "lg6urfk7yt2856xvlj565dho0",
        "Created": "2019-01-06T16:09:52.066700394+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.1.0/24",
                    "Gateway": "10.0.1.1"
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
            "f4675b26411e3178bbe2860b8da39ae95df7be695c6cd04a3d5cfbcfa3ba1bd0": {
                "Name": "my-nginx.4.farkvlh3jrswsu3uwedjslk8t",
                "EndpointID": "2c629c9e91b843eebb64c2e4920a44653368cf9f62fe60d428d42d0e33666c36",
                "MacAddress": "02:42:0a:00:01:03",
                "IPv4Address": "10.0.1.3/24",
                "IPv6Address": ""
            },
            "lb-nginx-net-2": {
                "Name": "nginx-net-2-endpoint",
                "EndpointID": "6c8735bec6a432754ed37e1da75f3d9eb71b4ef7cc7a92b9e8900c4723454b81",
                "MacAddress": "02:42:0a:00:01:04",
                "IPv4Address": "10.0.1.4/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4098"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "a4037138043d",
                "IP": "192.168.1.9"
            },
            {
                "Name": "b4d8838fb56f",
                "IP": "192.168.1.10"
            },
            {
                "Name": "746de4a0435c",
                "IP": "192.168.1.12"
            }
        ]
    }
]
```

> **[warning] 注意**
>
> 虽然 `orverlay` 网络会根据需要在工作节点上自动创建，但是不会自动删除。

- 在管理节点上运行下面命令将服务与网络进行删除。管理节点会自动引导工作节点删除网络。

```
$ docker service rm my-nginx
$ docker network rm nginx-net nginx-net-2
```

# 自定义 overlay 网络

因为在之前的默认 `overlay` 的网络中已经演示了自定义的 `overlay` 网络，因此这里只简单的说下。

- 创建自定义 `overlay` 网络

```
$ docker network create -d overlay my-overlay
```

- 使用自定义 `overlay` 网络运行服务，并将 `80` 端口发布到 Docker 主机的 `8080` 端口。

```
$ docker service create \
  --name my-nginx \
  --network my-overlay \
  --replicas 1 \
  --publish published=8080,target=80 \
  nginx:latest
  
xtoqr66jpj00wbqy1lwgc12v6
overall progress: 1 out of 1 tasks 
1/1: running   [==================================================>] 
verify: Service converged 

$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
xtoqr66jpj00        my-nginx            replicated          1/1                 nginx:latest        *:8080->80/tcp

```

- 运行 `docker network inspect my-overlay` 命令验证 `my-nginx` 服务任务已经连接到了该网络，另外要注意下 `containers` 中的信息。

```
$ docker network inspect my-overlay
[
    {
        "Name": "my-overlay",
        "Id": "kdj4cgpzgi3kgkp0q5o0ae6bk",
        "Created": "2019-01-06T16:34:43.91033391+08:00",
        "Scope": "swarm",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "10.0.2.0/24",
                    "Gateway": "10.0.2.1"
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
            "70372391d37d27fba62b8add60687bd7c534c1e14444c3c2d33c4f2cd3314284": {
                "Name": "my-nginx.1.akqwxtd6enefvlurqya06ta6t",
                "EndpointID": "bbfe904f4b3297f5b31643931513404ca6e675ad92a3ac1ed8d8a0d4a59939e9",
                "MacAddress": "02:42:0a:00:02:03",
                "IPv4Address": "10.0.2.3/24",
                "IPv6Address": ""
            },
            "lb-my-overlay": {
                "Name": "my-overlay-endpoint",
                "EndpointID": "be1a0ea5cb86a51031821bb39fdded9bc26e0d1ac43e48e4a15987ada20a3595",
                "MacAddress": "02:42:0a:00:02:04",
                "IPv4Address": "10.0.2.4/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.driver.overlay.vxlanid_list": "4099"
        },
        "Labels": {},
        "Peers": [
            {
                "Name": "a4037138043d",
                "IP": "192.168.1.9"
            }
        ]
    }
]
```

- 自定义的 `overlay` 网络只到这里，具体见默认的 `overlay` 网络中的有关说明，下面叫服务与网络进行删除。

```
$ docker service rm my-nginx

$ docker network rm my-overlay
```

# 在独立容器中使用 overlay 网络

本示例展示 DNS 容器的发现。准确来说，是在不同的 Docker 主机之间如何使用 `overlay` 网络实现独立容器的通信。具体步骤如下：

> **[success] 说明**
>
> 以下步骤中：
> `host1`：对应主机 `192.168.1.9`
> `host2`：对应主机 `192.168.1.10`

- 在 `host1` 主机上，初始化一个 `swarm`
- 在 `host2` 上加入该集群
- 在 `host1` 主机上创建 `overlay` 网络 `test-net`
- 在 `host1` 主机上，运行 `alpine` 容器（`alpine1`）并连接到 `test-net` 网络
- 在 `host2` 主机上，运行 `alpine` 容器（`alpine2`）并连接到 `test-net` 网络
- 在 `host1` 主机上的容器 `alpine1` 中 `ping` `alpine2`

另外，在执行以下步骤是要保证已经开启如下端口：

- TCP port 2377
- TCP and UDP port 7946
- UDP port 4789

---

- 在 `host1` 中初始化 `swarm`（同样的，如果出现提示。需要使用 `--advertise-addr` 指定与群中其他主机通信的接口的IP地址）

```
$ docker swarm init
Swarm initialized: current node (z62948o72kv6yx9rjpcv1hc9a) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-652zly2800j5tyxegghapcu6v5lr5qhqrssmk4q4572n70fnr5-3zmda20ogojaric5sm778zg53 192.168.1.9:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

- 在 `host2` 中加入 `swarm`

```
$ docker swarm join --token SWMTKN-1-652zly2800j5tyxegghapcu6v5lr5qhqrssmk4q4572n70fnr5-3zmda20ogojaric5sm778zg53 192.168.1.9:2377

This node joined a swarm as a worker.
```

注意，在加入节点之前需要退出已加入的 `swarm`，使用如下命令强制退出

```
$ docker swarm leave --force
```

- 在 `host1` 中，创建一个 `attachable` `overlay` 网络 `test-net`

```
$ docker network create --driver=overlay --attachable test-net
unpuqsxonmuf4oes6tohpjbk2
```

需要注意这个id，在连接 `host2` 时会再次看到该 ID。

- 在 `host1` 中运行一个可交互（`-it`）的容器 `alpine1` 并连接到 `test-host` 网络

```
$ docker run -it --name alpine1 --network test-net alpine
/ # 
```

- 在 `host2` 中列出网络信息，确定没有 `test-net` 网络

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
8f29fbe91663        bridge              bridge              local
0cde9a023dee        docker_gwbridge     bridge              local
1006fa4fcdc1        host                host                local
pr4jkgpe6d2o        ingress             overlay             swarm
ad1bf137cf18        none                null                local
```

- 在 `host2` 中后台运行（`-d`）一个可交互式（`-it`）的容器 `alpine2`，并连接到 `test-net` 网络。

```
$ docker run -dit --name alpine2 --network test-net alpine
6ac220e5010ed4b022d76c9cc69fde50d0b91a069c3ac06d34f7b55736efdc9d
```

自动DNS容器发现仅适用于唯一的容器名称。如果硬存在该容器名称将会提示如下错误：

```
$ docker run -dit --name alpine2 --network test-net alpine
docker: Error response from daemon: Conflict. The container name "/alpine2" is already in use by container "aa887162d56e47a2b9ec476ddd0a6cda025e2b73947f14acb434182375ba6dc7". You have to remove (or rename) that container to be able to reuse that name.
```

- 在 `host2` 中验证 `test-net` 网络是否已自动创建，并且 ID 与之前相同。

```
$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
...
l1d3jpr0kpbc        test-net            overlay             swarm
```

- 在 `host1` 中，`ping` `alpine2`。看能否 `ping` 通。

```
/ # ping -c 3 alpine2
PING alpine2 (10.0.0.6): 56 data bytes
64 bytes from 10.0.0.6: seq=0 ttl=64 time=0.529 ms
64 bytes from 10.0.0.6: seq=1 ttl=64 time=0.592 ms
64 bytes from 10.0.0.6: seq=2 ttl=64 time=0.523 ms

--- alpine2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.523/0.548/0.592 ms
```

两个容器与连接两个主机的 `overlay` 网络通信。如果你在 `host2` 在运行另外一个 `alpine` 容器是不能分离的。你可以在 `host2` `ping` `alpine1`。

```
$ docker run -it --rm --name alpine3 --network test-net alpine
/ # ping -c 3 alpine3
PING alpine3 (10.0.0.8): 56 data bytes
64 bytes from 10.0.0.8: seq=0 ttl=64 time=0.060 ms
64 bytes from 10.0.0.8: seq=1 ttl=64 time=0.070 ms
64 bytes from 10.0.0.8: seq=2 ttl=64 time=0.054 ms

--- alpine3 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.054/0.061/0.070 ms
```

- 清楚容器和网络。在清楚之前，你必须要先停止容器。因为Docker守护进程独立运行，这些是独立的容器。你只需要删除 `host1` 上的网络，因为当你在 
`host2` 上停止 `alpine2` 时，`test-net` 会消失。

在 `host2` 上停止 `alpine2` 检查 `test-net` 网络是否已自动移除。

```
$ docker container stop alpine2

$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
8f29fbe91663        bridge              bridge              local
46a1fa8aac76        docker_gwbridge     bridge              local
1006fa4fcdc1        host                host                local
kvizopvh3m8c        ingress             overlay             swarm
ad1bf137cf18        none                null                local

$ docker container rm alpine2
```

在 `host1` 中，停止、移除 `alpine1` 和 `test-net`

```
$ docker container stop alpine1
$ docker container rm alpine1
$ docker network rm test-net
```