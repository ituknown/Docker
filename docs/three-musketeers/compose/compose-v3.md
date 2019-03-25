# 前言

`docker-compose.yml` 文件主要用于编写服务。在编写时都需要在第一行中指定版本号（`v1` 除外）。当前 `docker-ce v18.09` 可使用最高版本为 `3`。
不同的版本语法之间有些诧异。具体版本号与 Docker Engine 之间的关系对应如下：

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
  ......
```

# docker-compose 示例

在介绍具体语法之前先来看下一个完整的示例：

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

# 参数配置

Compose 文件是定义服务，网络和卷的YAML文件。 Compose 文件的默认路径是 `./docker-compose.yml`。

服务定义包含应用于为该服务启动的每个容器的配置，就像将命令行参数传递给 `docker container create` 一样。同样，网络和卷定义类似于 `docker network create`
和 `docker volume create`。

与 `docker container create` 一样，Dockerfile 中指定的选项（例如 `CMD`，`EXPOSE`，`VOLUME`，`ENV`）在默认情况下也是可以使用的 - 因此
不需要在 `docker-compose.yml` 中再次指定。

你也可以使用类似 `Bash` 的 `${VARIABLE}` 语法在配置值中使用 [环境变量](#Variable)。

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

# cap_add,cap_drop

## Variable