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