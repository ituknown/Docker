# services 配置
## build

在构建应用时的配置选项，如构建镜像。

`build` 可以指定一个包含构建上下文的路径字符串：

```yaml
version: '3'
services:
  webapp:
    build: ./dir
```

你也可以使用 `build` 指定上下文中的 `Dockerfile` 文件或 `args`：

```yaml
version: '3'
services:
  webapp:
    build:
      context: ./dir
      dockerfile: Dockerfile
      args:
        buildon: 1
```

如果你使用 `build` 指定了构建一个镜像，你可以与 `image` 参数一起使用为构建的镜像指定具体的名称和 `tag`：

```yaml
version: '3'
services:
  webapp:
    image: webapp:tag
    build:
      context: ./dir
      dockerfile: Dockerfile
      args:
        buildon: 1
```

该构建的结果是构建从当前目录下的 `/dir` 文件中找到名为 `Dockerfile` 的文件构建具体的镜像，并且构建的镜像的名称为 `webapp` tag 为 `tag`。


> **[info] 小提示o**
>
> 该示例在 `docker stack swarm` 模式（version 3）下无法使用，因为 `docker stack` 只能使用预先构建完成的镜像。

### context

指定一个包含 `Dockerfile` 文件的文件夹路径（可以是相对或绝对路径）或者 `git` 仓库。

当指定的是相对路径时，相对路径是相对于 `docker-compose.yaml` 文件的路径。`docker-compose.yaml` 文件所在的路径也就是应用构建上下文。

在构建时可以为要构建的镜像通过 `image` 指定名称和标签，就能应用于服务。

```yaml
version： '3'
services:
  webapp:
    image: webapp:tag
    build:
      context: ./dir
```

### dockerfile

指定一个 `Dockerfile` 文件。

Compose 会使用指定的 `Dockerfile` 进行构建镜像，该选项必须与 `context` 配合使用，`context` 用于指定 `Dockerfile` 所在的目录。

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      dockerfile: Dockerfile-alternate
```

### args

增加参数，该参数只能在构建过程中使用。

使用该选项之前要在 `Dockerfile` 文件中定义：

```
ARG buildno
ARG gitcommithash

RUN echo "Build number: $buildno"
RUN echo "Bash on commit: $gitcommithash"
```

然后，即可在 docker-compose 文件中的 `build` key 下进行使用：

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      args:
        buildno: 1
        gitcommithash: cdc3b19
```

或者写成：

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      args:
        - buildno=1
        - gitcommithash=cdc3b19
```

另外，你也可以在指定构建参数时省略该值，在这种情况下，它在构建时的值是运行 Compose 的环境中的值

```yaml
args:
  - buildno
  - gitcommithash
```

> **[danger] 注意**
>
> 在 `yaml` 文件中的 `boolean` 类型的值（如：`true`,`false`,`yes`,`no`,`off` so on） 必须使用括号括起来，以便被解析器解释为字符串。

### cache_form

该选项是 `v3.2` 新增。

Docker 引擎用于从缓存中解析镜像列表。

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      cache_form:
        - alpine:latest
        - corp/web_app:3.14
```

### labels

该选项是 `v3.3` 新增。

该选项其实是通过使用 Docker labels 将元数据添加到生成的图像中，可以使用数组或字典：

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      labels:
        com.example.desception: "Accounting webapp"
        com.example.department: "Finance"
        com.example.label-with-empty-value: ""
```

或者

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      labels:
        - "com.example.description=Accounting webapp"
        - "com.example.department=Finance"
        - "com.example.label-with-empty-value"
```

### shm_size

该选项是 `v3.5` 新增。

为此构建的容器设置 `/dev/shm` 分区的大小。指定的值表示字节的整数值或字符串：

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      shm_size: '2gb'
```

或

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      shm_size: 10000000
```

### target

该选项是 `v3.4` 新增。

为构建 Dockerfile 中定义指定阶段。

```yaml
version: '3'
services:
  webapp:
    build:
      context: .
      target: prod
```

## configs

## container_name

为生成的容器指定一个名称。

注意，在同一机器中名称必须是唯一的。

```yaml
version: '3'
services:
  webapp:
    container_name: webapp
```

> **[info] 小提示o**
>
> 该选项在 `docker stack swarm` 模式（version 3）下无法使用。

## depends_on

定义服务之间的依赖关系。

看这个栗子：

```yaml
version: '3'

services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis:latest
  db:
    image: postgres:latest
```

- 当使用 `docker-compose up` 命令启动应用时，`db` 和 `redis` 服务会在 `web` 服务启动之前启动。
- `docker-compose up SERVICE` 会自动包含 `SERVICE` 的依赖项。如使用 `docker-compose up web` 时会同时启动 `redis` 和 `db` 服务。

> **[warning] 注意**
>
> 在启动 `web` 之前 `depends_on` 不会让 `db` 和 `redis` 预先准备好，而是在启动时。如果你需要控制服务的启动顺序可以点击 [传送门](https://docs.docker.com/compose/startup-order/) 查看具体配置信息。
> 另外，在 `v3` 版本中 `depends_on` 条件形式已经不再赞成使用，后续会逐渐弃用。
> 在 `docker stack swarm` 模式下是不支持 `depends_on` 选项的，即使增加该选项也会自动忽略。

## deploy

该选项仅支持 `v3`。

用于指定与部署和运行服务相关的配置。该选项仅适用于 `swarm` 集群服务，在单机模式下使用 `docker-compose up` 会自动忽略该选项。

```yaml
version: '3'
services:
  redis:
    image: redis:latest
    deploy:
      replicas: 6
      update_config:
        parallelism: 2
	delay: 10s
      restart_policy:
        condition: on-failure
```

另外还有如下几个可选的子选项：

### endpoint_mode

该参数仅适用于 `v3.3`。

为连接到集群的外部客户端指定服务发现方法。

- `endpoint_mode: vip` 为服务分配虚拟IP（`virtual IP`），这是默认发现策略。
- `endpoint_mode: dnssr` 不为服务分配单个虚拟IP，而是维护一套服务发现循环列表。

```yaml
version: '3.3'
services:
  wordpress:
    image: wordpress
    ports:
      - "8000:80"
    networks:
      - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: vip
  mysql:
    image: mysql
    volumes:
      - db-data:/var/lib/mysql/data
    networks:
      - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: dnsrr
volumes:
  db-data:
networks:
  overlay:
```

### labels

为服务设置标签。

注意，是为服务设置标签，而不是为服务中的容器。

```yaml
version: '3'
services:
  web:
    image: web
    deploy:
      labels:
        com.example.description: "This label will appear on all containers for the web service"
```

如果为容器设置标签，也是使用 `labels`。见下面示例：

```yaml
version: '3'
servies:
  web:
    image: web
    lables:
      com.example.description: "This label will appear on all containers for the web service"
```

### mode

为容器指定实例数。

- `global` 每个 `swarm` 节点只有一个容器。
- `replicated` 为容器指定任意多个实例（默认）。

```yaml
version: '3'
services:
  web:
    deploy:
      mode: replicated
      replicas: 2
```

```yaml
version: '3'
services:
  web:
    deploy:
      mode: global
```

### placement

指定约束和首选项的位置。

```yaml
version: '3'
services:
  web:
    deploy:
      placement:
        constraints:
          - node.role == manager
          - engine.labels.operatingsystem == ubuntu 14.04
        preferences:
          - spread: node.labels.zone
```

通过定义约束表达式来限制可以调度任务的节点集。多个约束查找满足每个表达式的节点（AND匹配）。约束可以匹配节点或Docker Engine标签，如下所示：

|node attribute	|matches	|example|
|:-------------:|:---------:|:-----:|
|node.id	|Node ID	|node.id==2ivku8v2gvtg4|
|node.hostname	|Node hostname	n|ode.hostname!=node-2|
|node.role	|Node role	|node.role==manager|
|node.labels	|user defined node labels	|node.labels.security==high|
|engine.labels	|Docker Engine's labels	|engine.labels.operatingsystem==ubuntu 14.04|

### replicas

如果服务部署使用的模式为 `replicated`（这是默认模式），你可以为服务容器指定任意多个节点。

```yaml
version: '3'
services:
  web:
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 6
```

### resources

配置资源限制。

这些中的每一个都是单个值，类似于 `docker service create`。

一般，redis 服务都会被限制为内存使用不超过 `50M` 和 `0.5`（单核 `50%`）的可处理时间（CPU）。并且具有 `20M` 内存和 `0.25` CPU始终可用区间。
按这个栗子来说配置如下所示：

```yaml
version: '3'
services:
  redis:
    image: redis:alpine
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 50M
        reservations:
          cpus: '0.25'
          memory: 20M
``` 

> **[danger] 注意**
>
> 如果部署的服务或容器尝试使用的内存超过系统可用的内存，则可能会遇到内存不足异常（OOME），并且内核OOM杀手可能会杀死容器或Docker守护程序。要防止
这种情况发生，需要确保的应用程序在具有足够内存的主机上运行。

### restart_policy

配置是否以及如何在容器退出时重启容器。可用于替换 `restart`。

- `condition`：可以是 `none`、`on-failure` 或者 `any`（默认）。
- `delay`: 用于设置重启尝试间隔，默认 0。
- `max_attempts`：在重启失败后最大尝试重启次数。注意，如果是在 `window` 配置内的重启失败则不计入。
- `window`：在决定重启是否成功之前等待多长时间。

```yaml
version: '3'
services:
  redis:
    image: redis:alpine
    deploy:
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
```

### update_config

配置服务应如何更新，用于配置滚动更新。

+ `parallelism`：一次更新的容器数。
+ `delay`：每次更新的时间间隔。
+ `failure_action`：更新失败后如何处理，`continus`、`rollbak` 或 `pause`（默认）。
+ `monitor`：每次更新任务后监视失败的持续时间 （`ns|us|ms|s|m|h`）（默认为0）。
+ `max_failure_ratio`：更新期间最大的失败率。
+ `order`：更新期间的操作顺序（仅仅支持 `v3.4+`）。
  - `stop-first`：在开始新任务之前停止旧任务（默认）。
  - `start-first`：首先启动新任务，并慢慢地覆盖正在运行的任务。
  
```yaml
version: '3.4'
services:
  vote:
    image: dockersamples
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
        order: stop-first
```

## command

覆盖默认的 `command`。

```
command: bundle exec thin -p 3000
```

另外，command 也可以是一个集合列表，同 Dockerfile：

```yaml
version: '3'
services:
  webapp:
    command: ["bundle","exec","thin","-p","3000"]
```

## entrypoint

覆盖默认 `entrypoint`：

```yaml
version: '3'
services:
  web:
    image: web:latest
    entrypoint: /code/entrypoint.sh
```

另外，也可以是一个 List 集合，同 Dockerfile。

```yaml
version: '3'
services:
  web:
    image: web:latest
    entrypoint:
      - php
      - -d
      - zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20100525/xdebug.so
      - -d
      - memory_limit=-1
      - vendor/bin/phpunit
```
> **[danger] 注意**
>
> 设置 `entrypoint` 都会使用 `ENTRYPOINT` Dockerfile指令覆盖服务镜像上设置的任何 `entrypoint`，并清除镜像上的默认命令。

## env_file

从文件添加环境变量。可以是单个值或列表。

如果已使用 `docker-compose -f FILE` 指定了 `Compose` 文件，则 `env_file` 中的路径相对于该文件所在的目录。

在环境部分中声明的环境变量会覆盖这些值 - 即使这些值为空或未定义。

```yaml
version: '3'
services:
  web:
    env_file: .env
```

```yaml
version: '3'
services:
  web:
    env_file:
      - ./common.env
      - ./apps/web.env
      - /opt/secrets.env
```

## expose

暴露端口而不将它们发布到主机 - 它们只能被链接服务访问。只能指定内部端口。

```yaml
version: '3'
services:
  web:
    expose:
      - "3000"
      - "8000"
```

## external_links

链接到此 `docker-compose.yml` 之外或甚至在 Compose 之外的容器，特别是对于提供共享或公共服务的容器。在指定容器名称和链接别名（`CONTAINER：ALIAS`）时，
`external_links` 语法同 `links`（`link` 已不赞成使用）。

```yaml
version: '3'
services:
  web:
    external_links:
      - redis_1
      - project_db_1:mysql
      - project_db_1:postgresql
```

## healthcheck

配置运行的检查以确定此服务的容器是否 *健康*。

```yaml
version: '3'
services:
  web:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

`test` 必须是字符串或列表。如果是列表，则第一项必须是 `NONE`，`CMD` 或 `CMD-SHELL`。如果它是一个字符串，它相当于指定 `CMD-SHELL` 后跟该字符串。

```
# Hit the local web app
test: ["CMD", "curl", "-f", "http://localhost"]
```

如上所述，但包装在 `/bin/sh` 中。有一下两种形式：

```
test: ["CMD-SHELL", "curl -f http://localhost || exit 1"]
```

```
test: curl -f https://localhost || exit 1
```

要禁用默认运行状况检查，可以使用 `disable：true` 。这相当于指定 `test：["NONE"]`。

```yaml
version: '3'
services:
  web:
    healthcheck:
      disable: true
```

## image

指定镜像

```yaml
version: '3'
services:
  web:
    image: redis
    image: ubuntu:14.04
    image: tutum/influxdb
    image: example-registry.com:4000/postgresql
    image: a4bc65fd
```

## init

该选项是 `v3.7` 新增。

在容器内运行 `init`，转发信号并重新获得进程。设置布尔值以使用默认 `init`，或指定自定义路径的路径。

```yaml
version: '3.7'
services:
  web:
    image: alpine:latest
    init: true
```

```yaml
version: '2.2'
services:
  web:
    image: alpine:latest
    init: /usr/libexec/docker-init
```

## logging

配置服务日志

```yaml
version: '3'
services:
  web:
    logging:
      driver: syslog
      option:
        syslog-address: "tcp//<ip>:<port>"
```

驱动程序名称指定服务容器的日志记录驱动程序，与 `docker run` 的 `--log-driver` 选项一样（[传送门](https://docs.docker.com/config/containers/logging/configure/)）。

默认值为 `json-file`：

```
driver: "json-file"
driver: "syslog"
driver: "none"
```

默认驱动程序 `json-file` 具有限制存储日志量的选项。为此，可以使用键值对来设置最大存储大小和最大文件数：

```
options:
  max-size: "200k"
  max-file: "10"
```

上面的配置示例会存储日志文件，日志达到最大大小200kB，会进行回滚。存储的各个日志文件的数量由 `max-file` 值指定。随着日志超出最大限制，将删除较旧
的日志文件以允许存储新日志。看下面这个栗子：

```yaml
version: '3.7'
services:
  some-service:
    image: some-service
    logging:
      driver: "json-file"
      options:
        max-size: "200k"
        max-file: "10"
```

## networks

配置网络，在服务中使用该选项必须配置顶级 `networks`。

```yaml
version: '3'
services:
  some-service:
    networks:
     - some-network
     - other-network
networks:
  some-network:
  other-network:
```

### aliases

为服务网络指定别名。

同一网络上的其他容器可以使用服务名称或此别名连接到其中一个服务的容器。同样，相同的服务可以在不同的网络上具有不同的别名。

```yaml
version: '3'
services:
  some-service:
    networks:
      some-network:
        aliases:
         - alias1
         - alias3
      other-network:
        aliases:
         - alias2
networks:
  some-network:
  other-network:
```

在下面的示例中，提供了三个服务（`web`，`worker`和 `db` ），以及两个网络（`new` 和 `legacy`）。可以在 `new` 网络上的主机名 `db` 以及
`legacy` 网络上访问 `db` 服务。

```yaml
version: '2'

services:
  web:
    build: ./web
    networks:
      - new

  worker:
    build: ./worker
    networks:
      - legacy

  db:
    image: mysql
    networks:
      new:
        aliases:
          - database
      legacy:
        aliases:
          - mysql

networks:
  new:
  legacy:
```

### IPV4_ADDRESS, IPV6_ADDRESS

在加入网络时为此服务指定容器的静态IP地址。

顶级网络部分中的相应网络配置必须具有包含每个静态地址的子网配置的 `ipam` 块。如果需要IPv6寻址，则必须设置 `enable_ipv6` 选项，并且必须使用版本
`2.x` Compose文件，如下所示。

```yaml
version: '2.1'

services:
  app:
    image: busybox
    command: ifconfig
    networks:
      app_net:
        ipv4_address: 172.16.238.10
        ipv6_address: 2001:3984:3989::10

networks:
  app_net:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
      -
        subnet: 172.16.238.0/24
      -
        subnet: 2001:3984:3989::/64
```

## ports

暴露端口。

指定两个端口（`HOST:CONTAINER`），或仅指定容器端口（选择短暂的主机端口）。

该语法有如下两种：

**短语法**：

```yaml
ports:
 - "3000"
 - "3000-3005"
 - "8000:8000"
 - "9090-9091:8080-8081"
 - "49100:22"
 - "127.0.0.1:8001:8001"
 - "127.0.0.1:5000-5010:5000-5010"
 - "6060:6060/udp"
```

**长语法**：

+ `target`：容器内部端口
+ `published`：主机端口
+ `protocol`：`tcp` 或 `udp`
+ `mode`：
  - `host`：在每个节点上发布主机端口
  - `ingress`：集群模式端口负载均衡

```yaml
version: '3'
services:
  web:
    ports:
      - target: 80
      published: 8080
      protocol: tcp
      mode: host
  
```

## restart

- `no` 默认的重启策略，并且在任何情况下都不会重新启动容器。
- `always` 容器始终重新启动。
- `on-failure` 如果退出代码指示出现故障错误，则该策略将重新启动容器。

```
restart: "no"
restart: always
restart: on-failure
restart: unless-stopped
```

> **[info] 小提示o**
>
> 该选项在 `docker stack swarm` 模式（version 3）下无法使用。

# secrets 配置

# volumes 配置

指定主机或命名 volumes。

可以将主机路径作为单个服务的定义的一部分进行安装，而无需在顶级卷中定义它。

但是，如果要跨多个服务重用卷，需要在顶级卷中定义命名卷。将命名卷与服务，群组和堆栈文件一起使用。

下面示例展示 `web` 服务使用的命名卷（`mydata`），以及为单个服务（`db` 服务 `volumes` 下的第一个路径）定义的绑定挂载。`db` 服务同时还使用名为
`dbdata` 的命名卷（`db` 服务 `volumes` 下的第二个路径），但使用旧的字符串格式定义它以挂载命名 volumes。必须在顶级卷键下列出命名卷，如图所示。

```yaml
version: '3.2'
services:
  web:
    image: nginx:alpine
    volumes:
      - type: volume
        source: mydata
        target: /data
        volume:
          nocopy: true
      - type: bind
        source: ./static
        target: /opt/app/static
  db:
    image: postgres:latest
    volumes:
      - "/var/run/postgres/postgres.sock:/var/run/postgres/postgres.sock"
      - "dbdata:/var/lib/postgresql/data"
      
volumes:
  mydata:
  dbdata:
```

在该示例中，具体配置信息如下：

+ `type`：`volume`、`bind` 或 `tmpfs`。
+ `source`：mount的源，主机上用于绑定挂载的路径，或顶级卷键中定义的卷的名称。不适用于 `tmpfs` 挂载。
+ `target`：容器中的路径。
+ `read_only`：是否只读。
+ `bind`：增加绑定选项：
  - `propagation`：用于绑定的传播模式。
+ `volume`：配置其他卷选项：
  - `nocopy`：用于在创建卷时禁用从容器复制数据。
+ `tmpfs`：配置其他 `tmpfs` 选项：
  - `size`：`tmpfs` 挂载大小(`bytes`)。

## external

如果设置为 `true`，则表示已在 `Compose` 之外创建了此卷。`docker-compose up` 不会尝试创建它，如果它不存在则会引发错误。

```yaml
version: '3'

services:
  db:
    image: postgres
    volumes:
      - data:/var/lib/postgresql/data

volumes:
  data:
    external: true
```

## name

为此卷设置自定义名称。 `name` 字段可用于引用包含特殊字符的卷。

```yaml
version: '3.4'
volumes:
  data:
    name: my-app-data
```

可以与 `external` 配合使用：

```yaml
version: '3.4'
volumes:
  data:
    external: true
    name: my-app-data
```

# Network 配置选项

顶级 `networks` 可以配置创建指定类型的网络，以便用于服务。

## driver

指定网络驱动类型。

默认的网络驱动取决于你的 Docker Engine 配置方式。不过大多数情况下，单机多为 `bridge`。`swarm` 集群多为 `overlay`。

```yaml
version: '3'
networks:
  namedNet:
    driver: overlay
```

如果网络驱动不可用则会输出错误信息。

使用内置网络（如`host`和`none`）的语法略有不同。定义名为 `host` 或 `none`（Docker已自动创建）的外部网络以及 `Compose` 可以使用的别名（在这些示例中为 `hostnet` 或 `nonet` ），
然后使用别名授予对该网络的服务访问权限。

```yaml
version: '3.7'
services:
  web:
    # ...
    networks:
      hostnet: {}

networks:
  hostnet:
    external: true
    name: host
```

```yaml
services:
  web:
    # ...
    networks:
      nonet: {}

networks:
  nonet:
    external: true
    name: none
```

## attachable

> Note: Only supported for v3.2 and higher.

仅在将 `driver` 设置为 `overlay` 时可用。如果设置为 `true`，则除服务外，独立容器可以附加到此网络。如果独立容器连接到覆盖网络，它可以与也从其
他 Docker 守护程序连接到覆盖网络的服务和独立容器进行通信。

```yaml
version: '3.2'
networks:
  mynet1:
    driver: overlay
    attachable: true
```
## internal

默认情况下，Docker还将桥接网络连接到它以提供外部连接。如果要创建外部隔离的覆盖网络，可以将此选项设置为 `true`。

## labels

使用Docker标签向容器添加元数据，可以使用数组或字典。

```yaml
version: '3'
networks:
  mynet:
    labels:
      com.example.description: "Financial transaction network"
      com.example.department: "Finance"
      com.example.label-with-empty-value: ""
```

```yaml
version: '3'
networks:
  mynet:
    labels:
      - "com.example.description=Financial transaction network"
      - "com.example.department=Finance"
      - "com.example.label-with-empty-value"
```

## external

如果设置为 `true`，则指定已在 Compose 之外创建此网络。 `docker-compose up` 不会创建它，如果它不存在则会引发错误。

```yaml
version: '3'

services:
  proxy:
    build: ./proxy
    networks:
      - outside
      - default
  app:
    build: ./app
    networks:
      - default

networks:
  outside:
    external: true
```

你也可以为该网络指定一个名字

```yaml
version: '3.5'
networks:
  outside:
    external:
      name: actual-name-of-network
```

## name

> Added in version 3.5 file format

为此网络设置自定义名称。名称字段可用于引用包含特殊字符的网络。

```yaml
version: '3.5'
networks:
  network1:
    name: my-app-net
```

可以配合 `external` 使用：

```yaml
version: '3.5'
networks:
  network1:
    external: true
    name: my-app-net
```