# 前言

其实在之间的 [Docker 服务](../../get-started/Services.md) 篇就已经使用过 `Docker Compose`。不过实现的是集群服务（`swarm service`），
这里就从一个简单的示例开始介绍 Docker Compose 的使用。

# 构建单机服务

由于之间构建的是集群服务（即 `docker swarn init` 或 `docker swarm join ...` 环境），在实际中并没有构建单机应用。其实单机应用同集群应用一样，
docker compose 语法并没有什么差别，只是有些语法不通用，这个后续作说明。下面就开始从无到有的构建一个单机应用。

- 进入任何目录创建文件夹 `stand-alone`

```
$ mkdir stand-alone
```

将 <a href="./_file/hello-world-1.0.0.jar">hello-world-1.0.0.jar</a> 拷贝至该目录（`右键` - `在新标签页中打开链接 实现下载`）。该
`jar` 文件运行后访问 `8080` 端口会返回 `HelloWorld` 信息，并且每次访问都会加一。

- 编写 Dockerfile 文件

```
$ ls
hello-world-1.0.0.jar

$ touch Dockerfile

$ cat Dockerfile

FROM itumate/jdk:8.0.0
RUN mkdir /app
ADD hello-world-1.0.0.jar /app
WORKDIR /app
CMD ["java","-jar","/app/hello-world-1.0.0.jar","--server.port=8080"]
```

`FROM` 指定的基础镜像 `itumate/jdk:8.0.0` 是笔者构建 jdk1.8 基础镜像。你也可以直接使用官方提供的 `openjdk` 镜像。当然，笔者构建的镜
像你也可以直接进行拉取。

`RUN` 指令创建一个文件夹 `/app`

`ADD` 指令将当前目录下的 `hello-world-1.0.0.jar` 文件拷贝至 `/app` 目录，当然你也可以直接使用 `CP` 指令。

`WORKDIR` 指令指定工作目录

`CMD` 指令指定运行容器时运行 `hello-world-1.0.0.jar` 并指定端口号 `8080`

Dockerfile 文件就五个指令，共创建五个层。当然实际可以简写，不过笔者为了清晰所以这样写。

- 编写 `docker-compose.yml` 文件

```
$ ls
hello-world-1.0.0.jar Dockerfile

$ touch docker-compose.yml

$ cat docker-compose.yml

version: "3"
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "80:8080"
```

`version` 指定版本号，这个后续做说明。

`services` 定义服务。

`web` 定义服务下的其中一个应用，名称为 `web`。

`build` 指令同 `docker build` 指令。

`context` 指定指令 Dockerfile 所在文件夹，`.` 表示当前目录。

`dockerfile` 指定 Dockerfile 文件。

`ports` 指令指定了服务启动时使用主机 `80` 端口映射容器 `8080` 端口。

这样，一个简单的 docker-compose 就定义完成。

# 启动单机服务

在当前目录下执行 `docker-compose up` 指令启动服务。注意，docker-compose 会使用默认服务名称，你也可以使用 `-p` 参数指定项目名称。

```
$ ls
hello-world-1.0.0.jar Dockerfile docker-compose.yml

$ docker-compose up

# 输出信息如下：
docker-compose up
Building web
Step 1/5 : FROM itumate/jdk:8.0.0
 ---> 8d8678770f0e
Step 2/5 : RUN mkdir /app
 ---> Running in 13ce9b2567f2
Removing intermediate container 13ce9b2567f2
 ---> 889213b22b13
Step 3/5 : ADD hello-world-1.0.0.jar /app
 ---> dc6355ab2c1a
Step 4/5 : WORKDIR /app
 ---> Running in 79b133a4af3f
Removing intermediate container 79b133a4af3f
 ---> ed4f734f6e87
Step 5/5 : CMD ["java","-jar","/app/hello-world-1.0.0.jar","--server.port=8080"]
 ---> Running in f44ca9233608
Removing intermediate container f44ca9233608
 ---> 5dc7a6e85260
Successfully built 5dc7a6e85260
Successfully tagged docker_web:latest
WARNING: Image for service web was built because it did not already exist. To rebuild this image you must use `docker-compose build` or `docker-compose up --build`.
Creating docker_web_1 ... done
Attaching to docker_web_1
web_1  | 
web_1  |   .   ____          _            __ _ _
web_1  |  /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
web_1  | ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
web_1  |  \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
web_1  |   '  |____| .__|_| |_|_| |_\__, | / / / /
web_1  |  =========|_|==============|___/=/_/_/_/
web_1  |  :: Spring Boot ::        (v2.1.3.RELEASE)
web_1  | 
web_1  | 2019-03-20 16:55:30.363  INFO 1 --- [           main] c.m.helloworld.HelloWorldApplication     : Starting HelloWorldApplication v1.0.0 on 5467cdbe3346 with PID 1 (/app/hello-world-1.0.0.jar started by root in /app)
web_1  | 2019-03-20 16:55:30.381  INFO 1 --- [           main] c.m.helloworld.HelloWorldApplication     : No active profile set, falling back to default profiles: default
web_1  | 2019-03-20 16:55:32.648  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 8080 (http)
web_1  | 2019-03-20 16:55:32.693  INFO 1 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
web_1  | 2019-03-20 16:55:32.693  INFO 1 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet engine: [Apache Tomcat/9.0.16]
web_1  | 2019-03-20 16:55:32.721  INFO 1 --- [           main] o.a.catalina.core.AprLifecycleListener   : The APR based Apache Tomcat Native library which allows optimal performance in production environments was not found on the java.library.path: [/usr/java/packages/lib/amd64:/usr/lib64:/lib64:/lib:/usr/lib]
web_1  | 2019-03-20 16:55:32.893  INFO 1 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
web_1  | 2019-03-20 16:55:32.894  INFO 1 --- [           main] o.s.web.context.ContextLoader            : Root WebApplicationContext: initialization completed in 2404 ms
web_1  | 2019-03-20 16:55:33.339  INFO 1 --- [           main] o.s.s.concurrent.ThreadPoolTaskExecutor  : Initializing ExecutorService 'applicationTaskExecutor'
web_1  | 2019-03-20 16:55:33.688  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
web_1  | 2019-03-20 16:55:33.694  INFO 1 --- [           main] c.m.helloworld.HelloWorldApplication     : Started HelloWorldApplication in 4.017 seconds (JVM running for 4.632)
``` 

从输出的信息中可看到，构建项目时使用的名称是 `web`，然后使用 Dockerfile 构建一个镜像。镜像构建完成后输出服务的日志信息。

你可以使用如下命令查看服务状态：

```
$ docker-compose ps

    Name                  Command               State          Ports        
----------------------------------------------------------------------------
docker_web_1   java -jar /app/hello-world ...   Up      0.0.0.0:80->8080/tcp

$ docker ps

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
5467cdbe3346        docker_web          "java -jar /app/hell…"   3 minutes ago       Up 3 minutes        0.0.0.0:80->8080/tcp   docker_web_1
```

可以从服务和容器输出信息看出，项目已将主机 `80` 端口映射到容器 `8080` 端口。访问 `localhost` 看输出信息：

```
$ curl localhost
Hello World - 0

$ curl localhost
Hello World - 1

$ curl localhost
Hello World - 2

.......
```

看到每访问一次就会增加一次访问次数。这样一个简单的单机服务就启动成功。

# 重构服务

修改原 `docker-compose.yml` 内容，修改后如下：

```yaml
version: "3"

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    volumes:
      - .:/app

volumes:
  web-data:
```

再次运行 `docker-compose up` 命令启动服务：

```
$ docker-compose up

Creating volume "docker_web-data" with default driver
Creating docker_web_1 ... done
Attaching to docker_web_1
web_1  | 
web_1  |   .   ____          _            __ _ _
web_1  |  /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
web_1  | ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
web_1  |  \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
web_1  |   '  |____| .__|_| |_|_| |_\__, | / / / /
web_1  |  =========|_|==============|___/=/_/_/_/
web_1  |  :: Spring Boot ::        (v2.1.3.RELEASE)
```

从输出的日志信息中可以看到，在修改部分内容之后再次使用 `docker-compose up` 命令启动服务并没有像第一次构建镜像。现在不做任何修改再次执行命令
`docker-compose up` 命令：

```
$ docker-compose up

docker_web_1 is up-to-date
Attaching to docker_web_1
web_1  | 
web_1  |   .   ____          _            __ _ _
web_1  |  /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
web_1  | ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
web_1  |  \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
web_1  |   '  |____| .__|_| |_|_| |_\__, | / / / /
web_1  |  =========|_|==============|___/=/_/_/_/
web_1  |  :: Spring Boot ::        (v2.1.3.RELEASE)
```

看到，这次的输出信息更加直接。原因是在使用 `docker-compose` 启动服务时会将信息进行缓存，当下载再起启动服务时会将两次的内容信息做对比。如果信息
做了修改那么进行修改容器信息并重新运行，否则不做任何修改。

这是 `docker-compose` 的一大优势。

另外，由于使用卷将当前目录下的内容挂载到容器中。当你写的应用程序有使用到这些文件时并且这些文件做了修改。那么你每次修改的文件信息都会在程序中体现出来。

# 关闭、下线单机服务

关闭服务如下命令：

```
# 停止服务
$ docker-compose stop
 or
# 停止服务并删除容器、网络、镜像和卷
$ docker-compose down
```

# 命令说明

- **后台运行服务**

在上面的示例中看到，每次启动服务时都会在控制台上输出日志信息。如果你退出日志那么响应的服务也会被杀死，所以，如果你想要服务在后台运行可以使用 `-d` 参数：

```
$ docker-compose up -d

docker-compose up -d
docker_web_1 is up-to-date
```

查看服务是否运行状态：

```
$ docker-compose ps
    Name                  Command               State           Ports         
------------------------------------------------------------------------------
docker_web_1   java -jar /app/hello-world ...   Up      0.0.0.0:8080->8080/tcp
```

- **运行一次性命令**

如果你想使用一次性命令可以使用 `run` 命令，例如，要查看Web服务可用的环境变量：

```
$ docker-compose run web env
```

- **停止服务**

```
$ docker-compose stop
```

- **下线服务并删除卷、网络和容器信息**

注意：当前版本如果要同时删除卷信息需要增加 `--volumes` 参数：

```
$ docker-compose down

# 同时删除卷增加 --volumes 参数
$ docker-compose --volumes
```

另外，除了这些命令外。docker-compose 单机服务还有一些可使用命令。你可以使用 `--help` 命令查询所有命令及命令的相信信息。示例：

```
# 查看全部命令(只列出部分信息,具体自己使用命令查看)
$ docker-compose --help

...
Commands:
  build              Build or rebuild services
  bundle             Generate a Docker bundle from the Compose file
  config             Validate and view the Compose file
  create             Create services
  down               Stop and remove containers, networks, images, and volumes
  events             Receive real time events from containers
  exec               Execute a command in a running container
  help               Get help on a command
  images             List images
  kill               Kill containers
  logs               View output from containers
  pause              Pause services
  port               Print the public port for a port binding
  ps                 List containers
  pull               Pull service images
  push               Push service images
  restart            Restart services
  rm                 Remove stopped containers
  run                Run a one-off command
  scale              Set number of containers for a service
  start              Start services
  stop               Stop services
  top                Display the running processes
  unpause            Unpause services
  up                 Create and start containers
  version            Show the Docker-Compose version information
  
# 查看某命令信息(只列出部分信息,具体自己使用命令查看)
$ docker-compose build --help

...
Options:
    --compress              Compress the build context using gzip.
    --force-rm              Always remove intermediate containers.
    --no-cache              Do not use cache when building the image.
    --pull                  Always attempt to pull a newer version of the image.
    -m, --memory MEM        Sets memory limit for the build container.
    --build-arg key=val     Set build-time variables for services.
    --parallel              Build images in parallel.
```