# Docker Stack 是什么？

Docker Stack（栈）是一组相互关联的服务，用于构成特定环境的服务（`service`）集合，他们之间可以共享依赖关系，可以一起进行 **编排** 和 **伸缩**。更主要的是，Docker Stack 是自动部署多个相互关联的服务的简便方法，而无需单独的定义每个服务。

自动部署从 `Docker Swarm` 中就可以了解动，不管是服务升级还是节点扩充都不需要杀死进程重新部署，完全的做到了无缝升级。`Docker Stack` 同样的做到了这点。

另外，`Docker Swarm` 由 `docker-compose.yml` 文件定义 **一个** 服务，`Docker Stack` 同样也是由 `YAML` 文件定义而且格式与 `swarm` 也相同。不同的是他可以定义一个或多个服务、定义服务的环境变量、部署标签、容器数量以及相关的环境的特定配置。

在使用 `swarm` 部署服务时一直使用 `docker stack deploy` 进行部署，事实上就已经使用了 `docker stack`。但之前是一直在集群上运行单个服务堆栈（`docker stack`），而 `docker stack` 完全能做到多个服务的堆栈。


# 机器准备

准备三台机器：

- `192.168.31.131`：管理节点
- `192.168.31.133`：工作节点
- `192.168.31.134`：工作节点

# Swarm 集群连接

在管理节点运行初始化 `docker swarm init` 集群命令，在工作节点中进行加入集群。

```
$ docker swarm init
Swarm initialized: current node (a5yy7q2vej26awg4u2oggsh2c) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-18r6yasvao26coicfgzuuaalj9jjqhbml5soynuq6veho9dc6p-9kx5o04muohxh57o00t5za92y 192.168.31.131:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

工作节点：

```
$ docker swarm join --token SWMTKN-1-18r6yasvao26coicfgzuuaalj9jjqhbml5soynuq6veho9dc6p-9kx5o04muohxh57o00t5za92y 192.168.31.131:2377
This node joined a swarm as a worker.
```

>注意：工作节点在加入管理节点之前，要保证管理节点已开启响应端口，具体见 [Docker 集群]()

节点加入后在管理节点查看响应节点：

```
$ docker node ls
ID                            HOSTNAME                STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
a5yy7q2vej26awg4u2oggsh2c *   localhost.localdomain   Ready               Active              Leader              18.09.0
wmqub1palaexbolc8oagv596x     localhost.localdomain   Ready               Active                                  18.09.0
x820d1ouccm5i8vnaqr15zmtb     localhost.localdomain   Ready               Active                                  18.09.0
```

节点加入成功

# 构建 visualizer 服务

在之前已经通过 `docker-compose.yml` 构建了 `ifkeeper/web-test:v1.0.3` 服务，使用 `docker stack` 部署多个多个服务的堆栈也很简单，只需要在之前的 `docekr-compose.yml` 做些修改即可。

在管理节点拷贝之前的 `YAML` 文件，命令为 `docker-compose-WITH-VISUALIZER.yml`，内容如下：

```yaml
version: "3"

services:
  api:
    image: ifkeeper/web-test:v1.0.3
    deploy:
      replicas: 3
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
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      replicas: 1
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet

networks:
  webnet:

```

可以看到相比之前只是多了：

```yaml
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      replicas: 1
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
```

这里增加了 `api` 的对等服务 `visualizer`。这个服务是个可视化服务，另外增加了 `volumes` 键（使可视化程序能够访问 `Docker` 的主机套接字文件） 和 `placement` 键（用于确保此服务仅在 `swarm` 管理节点上运行，而从不在工作节点上运行）。

下面就开始运行该堆栈服务：

```
$ docker stack deploy -c docker-stack-WITH-VISUALIZER.yml visualizer
Creating network visualizer_webnet
Creating service visualizer_api
Creating service visualizer_visualizer
```

在管理节点，查看服务运行情况：

T1
```
$ docker service ls
ID                  NAME                    MODE                REPLICAS            IMAGE                             PORTS
my5nlwo6t2v5        visualizer_api          replicated          0/3                 ifkeeper/web-test:v1.0.3          *:80->80/tcp
57rdpsjm06ds        visualizer_visualizer   replicated          0/1                 dockersamples/visualizer:stable   *:8080->8080/tcp
```

T2
```
$ docker service ls
ID                  NAME                    MODE                REPLICAS            IMAGE                             PORTS
my5nlwo6t2v5        visualizer_api          replicated          2/3                 ifkeeper/web-test:v1.0.3          *:80->80/tcp
57rdpsjm06ds        visualizer_visualizer   replicated          0/1                 dockersamples/visualizer:stable   *:8080->8080/tcp
```

T3
```
$ docker service ls
ID                  NAME                    MODE                REPLICAS            IMAGE                             PORTS
my5nlwo6t2v5        visualizer_api          replicated          3/3                 ifkeeper/web-test:v1.0.3          *:80->80/tcp
57rdpsjm06ds        visualizer_visualizer   replicated          1/1                 dockersamples/visualizer:stable   *:8080->8080/tcp
```

在 T1、T2 时间正在现在相关镜像，在T3时间运行并且部署成功。

在管理节点与工作节点分别查看正在运行镜像（任务），会看到在管理节点有两个运行中的容器，而工作节点都是只有一个：

管理节点
```
$ docker ps
CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS              PORTS               NAMES
02efb2b2560d        ifkeeper/web-test:v1.0.3          "java -jar /app/dock…"   3 minutes ago       Up 3 minutes                            visualizer_api.3.l3bltodx2o7wx5tp6y2fcjwes
0b48152f9a1a        dockersamples/visualizer:stable   "npm start"              3 minutes ago       Up 3 minutes        8080/tcp            visualizer_visualizer.1.ssv5jpu7z8o5cj9261idfsznd
```

工作节点
```
$ docker ps
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS               NAMES
f3ee0b92ebea        ifkeeper/web-test:v1.0.3   "java -jar /app/dock…"   2 minutes ago       Up 2 minutes                            visualizer_api.1.t8svu8agkpiiqeov345unod8c
```

由于在 `docker-compose-WITH-VISUALIZER` 中配置了 `constraints: [node.role == manager]`。因此，可视化程序并没有在工作节点中运行任务。

另外，可视化程序对外暴露的端口号为 `8080`，可以通过管理节点进行访问：`192.168.31.131:8080`
