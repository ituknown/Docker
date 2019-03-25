# 前言

Docker Compose 是一个定义并一次运行多个容器的管理工具。Compose 可以使用 `.yaml` 或 `.yml` 文件来配置服务。然后只需要单个命令即可从配置中创建
并运行所有服务。

其实，在之前的 [Docker 服务](../../get-started/Services.md) 中就已经使用过 Compose，如果使用过就发现使用起来特别简单。主要可能是不知道如何定
义 key 以及每个 key 对应的值。在 Compose 中会主要说下这些语法。

使用 Compose 只需要三个步骤：

- 使用 Dockerfile 定义镜像
- 在 Docker Compose 定义构成应用程序的服务
- 使用 `docker-compose up`（该命令适用于独立容器） 命令启动服务

一般，Docker Compose 的文件名称都定义为 `docker-compose.yml` 或 `docker-compose.yaml`。当然，该名称时随意定义的，`docker-compose.yml`
是默认的名称。在运行服务时是需要在同级目录执行 `docker-compose up` 命令运行即可，会自动找同级目录的 `docker-compose` 文件。如果是自定义的名称
你可能需要使用 `-f` 参数指定自定义的文件，如 `docker-compose -f <dir>/docker-compose-web.yml up`。

下面是一个简单的 `docker-compose.yml` 内容示例，仅供参考，以供后续说明介绍：

```yaml
version: '3'
services:
  web:
    build: .
    ports:
    - "5000:5000"
    volumes:
    - .:/code
    - logvolume01:/var/log
    links:
    - redis
  redis:
    image: redis
volumes:
  logvolume01: {}
```

Docker Compose 提供管理整个服务声明周期的命令：

- 运行、停止以及重启服务可以使用 `docker-compose build <option>`、`docker-compose start <option>`或`docker-compose restart <option>` 命令
- 查看服务运行状态可以使用 `docker-compose ps <option>` 命令
- 查询服务输出日子可以使用 `docker-compose logs <option>` 命令
- ......

另外，在编写 `docker-compose` 时需要指定版本信息。不同版本之间的语法有些差异，当前 `docker-ce v18.09` 可使用最高版本为 `3.x`。具体版本号与 Docker Engine 之间的关系对应如下：

|Compose-file version |	Docker Engine release|
|:-------------------:|:--------------------:|
|3.7	|18.06.0+|
|3.6	|18.02.0+|
|3.5	|17.12.0+|
|3.4	|17.09.0+|
|3.3	|17.06.0+|
|3.2	|17.04.0+|
|3.1	|1.13.1+|
|3.0	|1.13.0+|
|2.4	|17.12.0+|
|2.3	|17.06.0+|
|2.2	|1.13.0+|
|2.1	|1.12.0+|
|2.0	|1.10.0+|
|1.0	|1.9.1.+|

所以，当你使用的是 docker `v17.04.0+` 版本时在编写 `docker-compose.yaml` 文件时的 `version` 就可以指定 `3`：

```yaml
version: "3"
services:
  #......
```

# Compose 优势

**单机实现多隔离环境**

Compose 使用项目名称将各环境彼此隔离，在如下几种上下文下可以通过项目名称实现此功能：

- 在开发环境（主机）上，创建一个单一环境的多个副本。比如，你想要实现一个项目的各个功能分支运行稳定的副本。
- 在 CI 服务中，为防止构建互相干扰，可以将项目名称设为唯一的构建号。
- 在共享主机或开发机器上，为防止可能使用相同服务器名称的不同项目互相干扰。

在使用 Compose 构建服务时，默认的项目名称是目录的基名。你可以使用 `-p` 参数或使用 `COMPOSE_PROJECT_NAME` 变量项目自定义名称。

**创建容器时填充卷数据**

Compose 会保留服务使用的所有卷及数据。当使用 `docker-compose up` 在单主机部署服务时，如果发现之间已经运行过容器，它会将卷从旧的容器复制到新
容器。此过程可确保在卷中创建的任何数据都不会丢失。

**仅当修改时重新创建容器**

Compose 会缓存创建容器时的配置信息。当你重新启动未做更改的服务时，Compose 将重新使用现有容器。重用容器意味着你可以非常快速地更改环境。

**支持使用变量**

Compose 支持在 Compose 文件中使用变量。你可以使用这些变量为不同环境或不同用户自定义组合。具体用法见 [变量使用]()

你可以使用 `extends` 字段扩展 Compose 文件，也可以创建多个 Compose 文件。具体见 [扩展 Compose 变量]()。

# Compose 常用示例

**开发环境**

在开发软件时，在隔离环境中运行应用程序并实现交互的能力非常关键。Compose 命令行工具可用于创建这样的环境并实现交互功能。

Docker-compose 提供了一种记录和配置所有应用程序的服务依赖项（如数据库，队列，缓存，Web服务API等）的方法。使用 Compose 命令行工具，你可以使
用单个命令（`docker-compose up`）为每个依赖项创建和启动一个或多个容器。

**自动化测试**

任何持续部署（CD）或持续集成（CI）过程的一个重要部分是自动化套件。自动化端到端测试需要一个运行测试的环境。 Compose 提供了一种非常方便的方法来
为测试套件创建和销毁隔离的测试环境。通过在 Compose 文件中定义完整环境，就可以在几个命令中创建和销毁这些环境：

```
$ docker-compose up -d
$ ./run_tests
$ docker-compose down
```

# 小栗子

在介绍具体语法之前先来看下一个完整的示例，以 `v3` 为栗：

<!--sec data-title="Example Compose file version 3" data-id="section0" data-show=true ces-->
```yaml
version: "3"
services:

  redis:
    image: redis:alpine
    ports:
      - "6379"
    networks:
      - frontend
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  db:
    image: postgres:9.4
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      placement:
        constraints: [node.role == manager]

  vote:
    image: dockersamples/examplevotingapp_vote:before
    ports:
      - "5000:80"
    networks:
      - frontend
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
      restart_policy:
        condition: on-failure

  result:
    image: dockersamples/examplevotingapp_result:before
    ports:
      - "5001:80"
    networks:
      - backend
    depends_on:
      - db
    deploy:
      replicas: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 1
      labels: [APP=VOTING]
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
        window: 120s
      placement:
        constraints: [node.role == manager]

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]

networks:
  frontend:
  backend:

volumes:
  db-data:
```
<!--endsec-->

从上面的示例中可以体现如下信息：各项配置都是由顶级键(如：`services`、`networks`、`networks` 和 `volumes`）扩展而来。每个顶级键下是具体的
参数信息，如 `volumes` 顶级键定义一个 `db-data` volume。参数信息下就是用于定义参数的配置信息，如 `visualizer` 参数下是 `image` 和 `ports`
共同组织该选项表现的形式。

在 `docker-compose.yaml` 文件中，所有的参数、值都是由顶级键定义服务结构。该顶级键与其子级配置（例如 `build`，`deploy`，`depends_on`，
`networks` 等）共同定义服务信息。总的来说，`docker-compose` 文件总具体的格式为 `<key>: <option>: <value>`。