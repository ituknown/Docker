# 前言

Docker Compose 是一个定义并一次运行多个容器的管理工具。Compose 可以使用 `.yaml` 或 `.yml` 文件来配置服务。然后只需要单个命令即可从配置中创建
并运行所有服务。

其实，在之前的 [Docker 服务](../get-started/Services.md) 中就已经使用过 Compose，如果使用过就发现使用起来特别简单。主要可能是不知道如何定
义以及每个 key 对应的值。在 Compose 中会主要说下这些语法。

使用 Compose 只需要三个步骤：

- 使用 Dockerfile 定义镜像
- 在 Docker Compose 定义构成应用程序的服务
- 使用 `docker-compose up`（该命令适用于独立容器） 命令启动服务

一般，Docker Compose 的文件名称都定义为 `docker-compose.yml` 或 `docker-compose.yaml`。当然，该名称时随意定义的，`docker-compose.yml`
是默认的名称。在运行服务时是需要在同级目录执行 `docker-compose up` 命令运行即可，会自动找同级目录的 `docker-compose` 文件。如果是自定义的名称
你可能需要使用 `-f` 参数指定自定义的文件，如 `docker-compose -f <dir>/docker-compose-web.yml up`。

下面是一个简单的 `docker-compose.yml` 内容示例，仅供参考，共后续作说明：

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