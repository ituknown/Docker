# 安装 Docker-compose

Docker-compose 是 Docker 三剑客之一，具体见 [三剑客之 Compose]()。这里简单说下 CentOS 下如何安装。

在Linux上，可以直接从GitHub上的存储库发布页面下载 [Docker二进制文件](https://github.com/docker/compose/releases)。
按照链接中的说明操作，其中包括在终端中运行 `curl` 命令下载二进制文件。

使用如下命令进行下载最新版本：

```
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

<!--sec data-title="注意" data-id="section0" data-show=true ces-->
上面的命令仅仅只是一个示例，可能会过时。要确保使用的是最新版本，请检查 [GitHub上的存储库发布页面](https://github.com/docker/compose/releases)。
<!--endsec-->

命令执行示例：

```
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   617    0   617    0     0    683      0 --:--:-- --:--:-- --:--:--   683
100 11.1M  100 11.1M    0     0   843k      0  0:00:13  0:00:13 --:--:-- 1193k
```

下载完成后需要对二进制文件赋予可执行权限，使用如下命令：

```
$ sudo chmod +x /usr/local/bin/docker-compose
```

使用如下命令验证是否安装成功：

```
$ docker-compose --version
```

命令执行示例：

```
$ docker-compose --version
docker-compose version 1.23.1, build b02f1306
```

安装 `docker-compose` 到此结束，具体升级与下载这里不做说明。

# 搭建集群

这里使用如下两台机器进行搭建集群，系统都是 CentOS7：

- `192.168.31.130`：管理节点
- `192.168.31.131`：工作节点


# 编写 docker-compose

搭建集群与之前的 Service 一样，都是使用 `docker-compose.yml` 文件。其实之前的 Service 就是单机器集群的一个应用。

在 **`192.168.31.130`** 机器上进行编写 `docker-compose.yml`。

文件内容如下（内容与之前相同，因此不做说明）：

```yaml
version: "3"
services:
  api:
    image: ifkeeper/web-test:v1.0.4
    deploy:
      replicas: 5
      resources:
        limits:
          cpus: "0.1"
          memory: 1G
      restart_policy:
        condition: on-failure
    ports:
      - "80:80"
    networks:
      - webnet
networks:
  webnet:
```

文件编写完成之后，需要将该机器初始化为集群管理节点。

# 初始化管理节点

在 `192.168.31.130` 机器上创建集群并将该机器初始化为管理节点只需要执行如下命令：

```
$ docker-swarm init
```

命令执行示例：

```
$ docker swarm init
Swarm initialized: current node (zijckbg21bygtehzlameaa0t8) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5y6bh74vbdn3mesgvtttgtu3jy0c120z6dpc1acnozzsz4jy4q-8qifd7dwri7o7a3l78d5qhyik 192.168.31.130:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

可以看到命令执行完成后有如下几点提示：

1. 集群初始化完成，当前节点是一个管理者（管理节点）。
2. 工作者如果想要加入该集群需要执行如下命令进行加入：

```
$ docker swarm join --token SWMTKN-1-5y6bh74vbdn3mesgvtttgtu3jy0c120z6dpc1acnozzsz4jy4q-8qifd7dwri7o7a3l78d5qhyik 192.168.31.130:2377
```

3. 如果想要向当前集群增加管理节点需要执行如下命令，并按照提示进行后续操作：

```
$ docker swarm join-token manager
```

<!--sec data-title="补充说明" data-id="section1" data-show=true ces-->
初始化管理节点是也可以使用如下命令：

```
$ docker swarm init --advertise-addr <ip|interface>[:port]
```

即执行主机与端口。默认情况下，docker 会自动对当前机器进行分配，找到一个最优 ip。另外，docker 集群的默认端口号是 2376 或 2377，如果其中一个被占用，会自动进行分配另外一个。

如果当前机器存在多个 ip，使用 `docker swarm init` 命令进行初始化时存在问题就可以使用该命令进行手动指定。
<!--endsec-->

到此，管理节点常见完成。

# 运行服务

现在可以进入 `docker-compose.yml` 文件夹进行部署服务。使用如下命令进行部署：

```
$ docker stack deploy -c docker-compose.yml <stack_name>
```

命令执行示例：

```
[root@localhost ~]# docker stack deploy -c docker-compose.yml test
Creating network test_webnet
Creating service test_api
```

现在可以查看服务，使用如下命令：

```
$ docker service ls
```

命令执行示例：

```
[root@localhost ~]# docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                      PORTS
wrxw1k2dl69d        test_api            replicated          5/5                 ifkeeper/web-test:v1.0.4   *:80->80/tcp
```

可以看到服务成功启动，并且有五个任务正在运行。现在查看一下正在运行的容器，使用如下命令：

```
$ docker ps
```

命令执行示例：

```
[root@localhost ~]# docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                      PORTS
wrxw1k2dl69d        test_api            replicated          5/5                 ifkeeper/web-test:v1.0.4   *:80->80/tcp
[root@localhost yml]# docker ps
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS               NAMES
a1d46f094221        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   13 seconds ago      Up 8 seconds                            test_api.5.rxi684rcphtps5vzqjpryse4s
9a0fb2a78202        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   13 seconds ago      Up 8 seconds                            test_api.2.4mqp00fzjb51jp0bmbwv42qd2
9a877f3fbfe2        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   13 seconds ago      Up 8 seconds                            test_api.3.du7urrff2tngk92bojofjbtyt
6087aa25062a        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   13 seconds ago      Up 8 seconds                            test_api.4.owp0rtdwh1a3ndtsnje5x8uks
271c3f2ad5fb        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   13 seconds ago      Up 9 seconds                            test_api.1.z3zhifyw5f9r4snqwsltq8kq9
```

在来使用如下命令查看节点实例：

```
$ docker node ls
```

命令执行示例：

```
[root@localhost ~]# docker node ls
ID                            HOSTNAME                STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
zijckbg21bygtehzlameaa0t8 *   localhost.localdomain   Ready               Active              Leader              18.09.0
```

输出信息 `id` 后面的 `*` 表示当前连接到了该节点。`HOSTNAME` 栏输出节点的 `localhost`。`MANAGER` 用于指示 `swarm` 中的管理节点，该栏值为 `Leader` 表示为管理节点，空值表示为工作节点。

继续，还可以使用如下命令查看 `swarm` 当前状态：

```
$ docker info
```

命令执行示例（只列出主要节点信息）：

```
[root@localhost ~]# docker info
...
Swarm: active
 NodeID: zijckbg21bygtehzlameaa0t8
 Is Manager: true
 ClusterID: qmpv326rnashh6kakiy4rm2vq
 Managers: 1
 Nodes: 1
 Default Address Pool: 10.0.0.0/8  
 SubnetSize: 24
 Orchestration:
  Task History Retention Limit: 5
 ...
```

# 开启主机端口

按理说现在可以直接将 `192.168.31.131` 机器加入该集群成为一个工作节点，不过这里要做下重要说明。当在 `192.168.31.131` 机器执行加入节点命令时可能会提示如下错误：

```
Error response from daemon: rpc error: code = Unavailable desc = all SubConns are in TransientFailure, latest connection error: connection error: desc = "transport: Error while dialing dial tcp 192.168.31.130:2377: connect: no route to host"
```

原因是开启了防火墙或者说没有开放 `192.168.31.130` 主机的 `2377` 端口。下面就具体说明下：

<!--sec data-title="firewall 防火墙" data-id="section2" data-show=true ces-->

如果你使用的是 `firewall` 防火墙可以使用如下命令查看主机开放的端口：

```
$ firewall-cmd --zone=public --list-ports
```

如果没有输出或者输出的结果中没有需要的端口说明没有开放该端口。可以使用如下命令进行开放端口：

```
$ firewall-cmd --zone=public --add-port=<portid>[-<portid>]/<protocol>
```

如，笔者想要开放主机的 80 `tcp` 端口执行如下命令即可：

```
$ firewall-cmd --zone=public --add-port=80/tcp
```

不过，使用 `Docker Swarm` 主机之间的以下端口必须是开放。某些环境下，这些端口默认是允许的：

- `TCP` 端口 `2377` 用于集群管理通信（管理节点）
- `TCP` 和 `UDP` 端口 `7946` 用于节点间通信（所有节点）
- `TCP` 和 `UDP` 端口 `4789` 用于 `overlay` 网络流量（所有节点）

不过建议将 `TCP` 端口 `2376` 也进行开放。

开启以上端口之下如下命令即可：

```
firewall-cmd --zone=public --add-port=2376/tcp
firewall-cmd --zone=public --add-port=2377/tcp
firewall-cmd --zone=public --add-port=4789/tcp
firewall-cmd --zone=public --add-port=4789/udp
firewall-cmd --zone=public --add-port=7946/tcp
firewall-cmd --zone=public --add-port=7946/udp
```

如果想要永久开启这些端口，只需要在命令后加上 `--permanent` 命令即可。

示例：

```
firewall-cmd --zone=public --add-port=2376/tcp --permanent
```

如果想要关闭端口只需要执行如下命令即可：

```
firewall-cmd --zone=public --remove-port=<portid>[-<portid>]/<protocol>
```

命令执行示例：

```
firewall-cmd --zone=public --remove-port=2376/tcp
```

如果想要关闭 `firewall` 防火墙，可以执行如下命令：

```
# 停止firewall  
$ sudo systemctl stop firewalld.service  
# 禁止firewall开机启动  
$ sudo systemctl disable firewalld.service
```

想要启动 `firewall` 防火墙可以使用如下命令：

```
# 启动 firewall  
$ sudo systemctl start firewalld.service  
# 重启 firewall  
$ sudo systemctl restart firewalld.service
# 允许firewall 开机启动  
$ sudo systemctl enable firewalld.service
```

使用一下命令查看 `firewall` 防火墙状态，`running` 表示已启动，`not running` 表示未启动：

```
$ firewall-cmd --state
```

开放完成以上端口之后可以使用如下命令查看开放的端口：

```
$ firewall-cmd --zone=public --list-ports
```

命令执行示例：

```
[root@localhost ~]# firewall-cmd --zone=public --list-ports
7946/tcp 7946/udp 4789/udp 4789/tcp 2377/udp 2377/tcp
```
<!--endsec-->

<!--sec data-title="iptables 防火墙" data-id="section3" data-show=true ces-->
如果你使用的是 `iptables` 防火墙，执行以下命令开启即可：

```
iptables -A INPUT -p tcp --dport 2377 -j ACCEPT
iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
iptables -A INPUT -p udp --dport 7946 -j ACCEPT
iptables -A INPUT -p tcp --dport 4789 -j ACCEPT
iptables -A INPUT -p udp --dport 4789 -j ACCEPT

或者编辑防火墙文件，增加端口
$ vim /etc/sysconfig/iptables
  
# 编辑文件内容开启如下端口：
-A INPUT -p tcp --dport 2377 -j ACCEPT
-A INPUT -p tcp --dport 7946 -j ACCEPT
-A INPUT -p udp --dport 7946 -j ACCEPT
-A INPUT -p tcp --dport 4789 -j ACCEPT
-A INPUT -p udp --dport 4789 -j ACCEPT
```



扩展：

```
#启动设置防火墙
systemctl start iptables
systemctl start iptables.service 

# 开启自动启动
systemctl enable iptables
systemctl enable iptables.service 

#查看防火墙状态
systemctl status iptables
```

**注意:**

如果想要关闭和卸载 `iptables` 防火墙，千万不要使用如下命令：

```
$ yum remove iptables
```

这样操作会卸载掉很多系统必要的组件，那就开不了机了，链接不上了。切记切记。

如果想永远停用，使用以下命令即可：

```
$ chkconfig iptables off
```

停用后启用：

```
$ chkconfig iptables on
```
<!--endsec-->

现在断开已经开启了，就可以加入工作节点了。

# 加入工作节点

现在在 `192.168.31.131` 主机执行如下命令即可加入集群成为一个工作节点：

```
$ docker swarm join --token <token>
```

命令执行示例：

```
[root@localhost /]# docker swarm join --token SWMTKN-1-5y6bh74vbdn3mesgvtttgtu3jy0c120z6dpc1acnozzsz4jy4q-8qifd7dwri7o7a3l78d5qhyik 192.168.31.130:2377
This node joined a swarm as a worker.
```

表示加入集群成为一个工作节点成功。

现在，在管理节点（`192.168.31.130`）执行如下命令查看节点：

```
$ docker node ls
```

命令执行示例：

```
[root@localhost ~]# docker node ls
ID                            HOSTNAME                STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
ugwr3r0san0qhu068n0bu581x     localhost.localdomain   Ready               Active                                  18.09.0
zijckbg21bygtehzlameaa0t8 *   localhost.localdomain   Ready               Active              Leader              18.09.0
```

可以看到，在节点中一节存在了该节点。

继续在管理节点（`192.168.31.130`）执行 `docker info` 命令查看节点信息：

```
[root@localhost ~]# docker info
...
Swarm: active
 NodeID: zijckbg21bygtehzlameaa0t8
 Is Manager: true
 ClusterID: qmpv326rnashh6kakiy4rm2vq
 Managers: 1
 Nodes: 2
 Default Address Pool: 10.0.0.0/8  
 SubnetSize: 24
 Orchestration:
  Task History Retention Limit: 5
...
```

然后在工作节点（`192.168.31.131`）执行 `docker info` 命令：

```
[root@localhost ~]# docker info
...
Swarm: active
 NodeID: ugwr3r0san0qhu068n0bu581x
 Is Manager: false
 Node Address: 192.168.31.131
 Manager Addresses:
  192.168.31.130:2377
...
```

可以看到：
- 工作节点角色： `Is Manager: false`
- 节点地址：`Node Address: 192.168.31.131`
- 管理节点地址：`Manager Addresses:192.168.31.130:2377`

到此，工作节点就已经加入到了集群。

# 无缝升级与规模扩充

增加工作节点就是为了扩展服务能力。下面就来看下如下做到无缝升级、降级与规模扩充。

<!--sec data-title="规模扩充" data-id="section5" data-show=true ces-->
之前新浪开发者说过一句很牛的话：**我们的服务器现在支持3个明星同时出轨**。

后来，一个明星结婚 ...... 服务器爆了 ~

现在来看下如何增加节点，在 **管理节点** 直接修改 `docker-compose.yml` 文件，修改内容如下：

```yaml
version: "3"
services:
  api:
    image: ifkeeper/web-test:v1.0.4
    deploy:
      replicas: 20
```

简单点，就将节点由 5 个扩充到 20 个。然后直接在 **管理节点** 执行如下命令进行部署即可：

```
$ docker stack deploy -c docker-compose.yml test
```

命令执行示例：

```
[root@localhost ~]# docker stack deploy -c docker-compose.yml test
Updating service test_api (id: wrxw1k2dl69d8jw1xrv235x9b)
```

再来在 **管理节点** 执行如下命令查看服务状态：

```
$ docker servics ls
```

命令执行示例：

```
[root@localhost ~]# docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                      PORTS
wrxw1k2dl69d        test_api            replicated          10/20               ifkeeper/web-test:v1.0.4   *:80->80/tcp
[root@localhost ~]# docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                      PORTS
wrxw1k2dl69d        test_api            replicated          20/20               ifkeeper/web-test:v1.0.4   *:80->80/tcp
```

可以看到服务任务逐渐升到 20 个。

可以在 **管理节点** 使用如下命令查看当前是不是有 20 个工作任务：

```
$ docker service ps <service_name>
```

命令执行示例：

```
[root@localhost ~]# docker service ps test_api
ID                  NAME                IMAGE                      NODE                    DESIRED STATE       CURRENT STATE                ERROR               PORTS
z3zhifyw5f9r        test_api.1          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                        
4mqp00fzjb51        test_api.2          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                        
du7urrff2tng        test_api.3          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                        
owp0rtdwh1a3        test_api.4          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                        
rxi684rcphtp        test_api.5          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                        
qc0658agoqpk        test_api.6          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 2 minutes ago                            
wfb5ia7mhp02        test_api.7          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 2 minutes ago                            
xekv1ko39wa3        test_api.8          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
xci79oar0tv3        test_api.9          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
0oxb1v579ik3        test_api.10         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
l962f3bhvss3        test_api.11         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
o6yv7x6qwwb3        test_api.12         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
usywsku6h3w6        test_api.13         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 2 minutes ago                            
w7ngl245ym49        test_api.14         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 2 minutes ago                            
l8f7tulcec1n        test_api.15         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 2 minutes ago                            
9xwle7cnrjqn        test_api.16         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
265ijlsoy7d3        test_api.17         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
zyprqz3lrmjq        test_api.18         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
7da39vrof5mj        test_api.19         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago                       
5zrrun23dbji        test_api.20         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about a minute ago
```

再来在 **管理节点** 执行如下命令查看管理节点正在运行的容器（任务）数量：

```
$ docker ps
```

命令执行示例：

```
[root@localhost ~]# docker ps
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS               NAMES
da2924b1293e        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   2 minutes ago       Up 2 minutes                            test_api.7.wfb5ia7mhp02n92ko6mrg8805
a67839d181a0        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   2 minutes ago       Up 2 minutes                            test_api.14.w7ngl245ym49rpyyr0sao5z9b
337a5275c4a1        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   2 minutes ago       Up 2 minutes                            test_api.6.qc0658agoqpky8bigw6vpvzyh
06f27f725ce8        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   2 minutes ago       Up 2 minutes                            test_api.13.usywsku6h3w6igsugegmv74w9
84504d431e82        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   2 minutes ago       Up 2 minutes                            test_api.15.l8f7tulcec1nrpkw7hv2r3tau
a1d46f094221        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   About an hour ago   Up About an hour                        test_api.5.rxi684rcphtps5vzqjpryse4s
9a0fb2a78202        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   About an hour ago   Up About an hour                        test_api.2.4mqp00fzjb51jp0bmbwv42qd2
9a877f3fbfe2        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   About an hour ago   Up About an hour                        test_api.3.du7urrff2tngk92bojofjbtyt
6087aa25062a        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   About an hour ago   Up About an hour                        test_api.4.owp0rtdwh1a3ndtsnje5x8uks
271c3f2ad5fb        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   About an hour ago   Up About an hour                        test_api.1.z3zhifyw5f9r4snqwsltq8kq9
```

再在 **工作节点** 执行上面的命令查看运行容器（任务）：

```
[root@localhost /]# docker ps
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS               NAMES
c80d8086857a        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.16.9xwle7cnrjqneso41a8lpkf2y
9da11cfefd69        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.12.o6yv7x6qwwb3ouo82n51ogvra
cd1ba09b7ca8        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.11.l962f3bhvss3kqj6eqtykkojk
c64b63a17a03        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.10.0oxb1v579ik3mm4331og5qsz3
eb7a7d3ee1f3        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.18.zyprqz3lrmjq2dzk3n1zpmrmn
c787d6d036ba        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.8.xekv1ko39wa3qtty7fiuaioyu
6552fe039e48        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.19.7da39vrof5mjd31bgj5au5mqb
52c797ba6dfd        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.20.5zrrun23dbjimd6wrav7mkcub
a827a7bf7054        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.9.xci79oar0tv3l7ooclpjs3iw5
f13a657579ca        ifkeeper/web-test:v1.0.4   "java -jar /app/dock…"   7 minutes ago       Up 6 minutes                            test_api.17.265ijlsoy7d34tgrzu2hq1h74
```

可以看到一共 20 个实例（任务），工作节点与管理节点分别分担了 10 个实例（任务）。这就是 `swarm` 的均衡能力。

现在，就做到了在工作节点扩充服务能力。

**注意：** 涉及管理节点的命令都需要在管理节点进行执行，在工作节点执行会提示如下错误：

```
Error response from daemon: This node is not a swarm manager. Worker nodes can't be used to view or modify cluster state. Please run this command on a manager node or promote the current node to a manager.
```

<!--endsec-->

<!--sec data-title="无缝升级、降级" data-id="section6" data-show=true ces-->
在 [Docker 服务](./Services.md) 中已经介绍了无缝升级，这里就说下无缝降级。

之前的 `v1.0.4` 版本存在严重的安全技术漏洞，而之前的 `v1.0.3` 版本没有这个问题。想要修复又无法及时修复，无奈，只能用之前的版本进行暂时代替。

现在，在 **管理节点** 修改 `docker-compose.yml` 文件。内容如下：

```yaml
version: "3"
services:
  api:
    image: ifkeeper/web-test:v1.0.3
    deploy:
      replicas: 20
```

可以看到，仅仅修改了镜像版本。现在进行重新部署，直接执行如下命令即可：

```
$ docker stack deploy -c docker-compose.yml <stack_name>
```

命令执行示例：

```
[root@localhost ~]# docker stack deploy -c docker-compose.yml test
Updating service test_api (id: wrxw1k2dl69d8jw1xrv235x9b)
```

再来看下服务状态：

```
[root@localhost ~]# docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                      PORTS
wrxw1k2dl69d        test_api            replicated          20/20               ifkeeper/web-test:v1.0.3   *:80->80/tcp
```

可以看到镜像版本现在是 `v1.0.3`。说明已经做到了版本降级。

现在再来看下服务任务状态，执行如下命令：

```
$ docker service ps <servie_name>
```

命令执行示例：

*T1 时刻*

```
[root@localhost ~]# docker service ps test_api
ID                  NAME                IMAGE                      NODE                    DESIRED STATE       CURRENT STATE               ERROR               PORTS
z3zhifyw5f9r        test_api.1          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                       
4mqp00fzjb51        test_api.2          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                       
du7urrff2tng        test_api.3          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running about an hour ago                       
wzz59isgp2bg        test_api.4          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 17 seconds ago                          
owp0rtdwh1a3         \_ test_api.4      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 20 seconds ago                         
miheucg3re5o        test_api.5          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 seconds ago                           
rxi684rcphtp         \_ test_api.5      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 5 seconds ago                          
beev83av0h5z        test_api.6          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 9 seconds ago                           
qc0658agoqpk         \_ test_api.6      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 11 seconds ago                         
wfb5ia7mhp02        test_api.7          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 16 minutes ago                          
xekv1ko39wa3        test_api.8          ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
v4uqoowqv6df        test_api.9          ifkeeper/web-test:v1.0.3   localhost.localdomain   Ready               Preparing 3 seconds ago                         
xci79oar0tv3         \_ test_api.9      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Running 3 seconds ago                           
0oxb1v579ik3        test_api.10         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
l962f3bhvss3        test_api.11         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
o6yv7x6qwwb3        test_api.12         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
usywsku6h3w6        test_api.13         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 16 minutes ago                          
w7ngl245ym49        test_api.14         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 16 minutes ago                          
l8f7tulcec1n        test_api.15         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 16 minutes ago                          
9xwle7cnrjqn        test_api.16         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
265ijlsoy7d3        test_api.17         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
zyprqz3lrmjq        test_api.18         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
7da39vrof5mj        test_api.19         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago                          
5zrrun23dbji        test_api.20         ifkeeper/web-test:v1.0.4   localhost.localdomain   Running             Running 15 minutes ago
```

*T2时刻*

```
[root@localhost ~]# docker service ps test_api
ID                  NAME                IMAGE                      NODE                    DESIRED STATE       CURRENT STATE            ERROR               PORTS
hz0guv3zluet        test_api.1          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
z3zhifyw5f9r         \_ test_api.1      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
lzwo3bkcl795        test_api.2          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
4mqp00fzjb51         \_ test_api.2      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
o6j14b1w0otc        test_api.3          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 2 minutes ago                        
du7urrff2tng         \_ test_api.3      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 2 minutes ago                       
wzz59isgp2bg        test_api.4          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 minutes ago                        
owp0rtdwh1a3         \_ test_api.4      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 4 minutes ago                       
miheucg3re5o        test_api.5          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 minutes ago                        
rxi684rcphtp         \_ test_api.5      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 4 minutes ago                       
beev83av0h5z        test_api.6          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 minutes ago                        
qc0658agoqpk         \_ test_api.6      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 4 minutes ago                       
1yawgbgkzpvj        test_api.7          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
wfb5ia7mhp02         \_ test_api.7      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
mwkwhz70o9kc        test_api.8          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 minutes ago                        
xekv1ko39wa3         \_ test_api.8      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 4 minutes ago                       
v4uqoowqv6df        test_api.9          ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 minutes ago                        
xci79oar0tv3         \_ test_api.9      ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 4 minutes ago                       
vgbv6oi9cdae        test_api.10         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 2 minutes ago                        
0oxb1v579ik3         \_ test_api.10     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 2 minutes ago                       
ns412sfom4wl        test_api.11         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
l962f3bhvss3         \_ test_api.11     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
nfny0n3h9df8        test_api.12         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
o6yv7x6qwwb3         \_ test_api.12     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
uf6q5ozw7n9v        test_api.13         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
usywsku6h3w6         \_ test_api.13     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
woksbyh87627        test_api.14         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
w7ngl245ym49         \_ test_api.14     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
cjciq179py89        test_api.15         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 2 minutes ago                        
l8f7tulcec1n         \_ test_api.15     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 2 minutes ago                       
kar54nj1k0e1        test_api.16         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
9xwle7cnrjqn         \_ test_api.16     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
kntxwyznus85        test_api.17         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 2 minutes ago                        
265ijlsoy7d3         \_ test_api.17     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 2 minutes ago                       
ck42r0yfipvf        test_api.18         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 3 minutes ago                        
zyprqz3lrmjq         \_ test_api.18     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 3 minutes ago                       
fowwkpr3c2wd        test_api.19         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 minutes ago                        
7da39vrof5mj         \_ test_api.19     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 4 minutes ago                       
2batoetl5f93        test_api.20         ifkeeper/web-test:v1.0.3   localhost.localdomain   Running             Running 4 minutes ago                        
5zrrun23dbji         \_ test_api.20     ifkeeper/web-test:v1.0.4   localhost.localdomain   Shutdown            Shutdown 4 minutes ago
```

可以一目了然的看到，服务任务在一个一个的进行版本降级替换。这样，在其中一个任务进行版本降级的时候，其他的任务依然在提供服务状态。

**注意：** 涉及管理节点的命令都需要在管理节点进行执行，在工作节点执行会提示如下错误：

```
Error response from daemon: This node is not a swarm manager. Worker nodes can't be used to view or modify cluster state. Please run this command on a manager node or promote the current node to a manager.
```

<!--endsec-->

# 访问群集

集群就是一个服务，只是该服务有多个工作节点。具体访问这里不做说明，在 [Docker 服务](./Services.md) 已经做过说明。

两个IP地址工作的原因是群中的节点参与入口路由网格。这可确保部署在 `swarm` 中某个端口的服务始终将该端口保留给自身，无论实际运行容器的是哪个节点。
下面是一个图表，说明在三节点群上的 `my-web` 端口 `8080` 上发布的服务的路由网格如何显示：

![ingress-routing-mesh.png](_images/swarms/ingress-routing-mesh.png)
图是盗的，但内容是真的~

> **[warning] 有连接麻烦？**
>
> 请记住，要在群集中使用入口网络，您需要在启用群集模式之前在群集节点之间打开以下端口：
> - 端口7946 TCP / UDP用于容器网络发现。
> - 端口4789 UDP用于容器入口网络。

# 服务下线

下线的原因不说了，就说下怎么做到服务下线。

在我们1部署服务的时候记得执行的是如下命令：

```
$ docker stack deploy -c docker-compose.yml <stack_name>
```

下线服务将 **堆栈和集群（`Stacks and swarms`）** 移除即可，使用如下命令：

```
$ docker stack rm <stack_name>
```

命令执行示例：

```
[root@localhost ~]# docker stack rm test
Removing service test_api
Removing network test_webnet
```

可以看到，使用该命令就将服务与网络接口都进行移除了。这样才真正做到了 **服务下线与数据清理** ！

在管理节点执行查看服务命令，查看是否还有服务：

```
[root@localhost ~]# docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
```

查看是否还有运行中的容器：

```
[root@localhost ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

到此，服务已经下线了。但是该机器依然是一个节点，可以使用 `docker info` 命令查看 `swarm` 状态，想要退出节点执行如下命令：

```
# -f 表示强制退出
$ docker swarm leave -f
```

在看下工作节点：

```
...
Swarm: active
 NodeID: ugwr3r0san0qhu068n0bu581x
 Is Manager: false
 Node Address: 192.168.31.131
 Manager Addresses:
  192.168.31.130:2377
...
```

虽然管理节点已经下线，但是当前节点依然是一个工作节点，只是连接不上管理节点。因此，如果管理节点突然无故宕机，就可以在工作节点执行如下命令晋升至管理节点：

```
$ docker swarm join-token manager
```

工作节点如果也要下线，同样执行 `docker swarm leave -f` 即可，然后清除运行的任务即可。

到此，多机器集群部署就已经完成了~
