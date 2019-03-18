# 编写应用

在前面已经成功构建了 jvm8 镜像，现在笔者就基于该镜像构建第一个应用。

这里就写个简单的应用，直接使用 SpringBoot 构建。在应用中定义一个获取客户机器 ip 的工具类，如下所示：

```java
public class RequestUtils {

	private RequestUtils() {
	}

	private static final String UNKNOWN_IP = "unknown";

	public static String getIpAddress(HttpServletRequest request) {
		String ip = request.getHeader("X-Forwarded-For");
		if (ip == null || ip.length() == 0 || UNKNOWN_IP.equalsIgnoreCase(ip)) {
			if (ip == null || ip.length() == 0 || UNKNOWN_IP.equalsIgnoreCase(ip)) {
				ip = request.getHeader("Proxy-Client-IP");
			}
			if (ip == null || ip.length() == 0 || UNKNOWN_IP.equalsIgnoreCase(ip)) {
				ip = request.getHeader("WL-Proxy-Client-IP");
			}
			if (ip == null || ip.length() == 0 || UNKNOWN_IP.equalsIgnoreCase(ip)) {
				ip = request.getHeader("HTTP_CLIENT_IP");
			}
			if (ip == null || ip.length() == 0 || UNKNOWN_IP.equalsIgnoreCase(ip)) {
				ip = request.getHeader("HTTP_X_FORWARDED_FOR");
			}
			if (ip == null || ip.length() == 0 || UNKNOWN_IP.equalsIgnoreCase(ip)) {
				ip = request.getRemoteAddr();
			}
		} else if (ip.length() > 15) {
			String[] ips = ip.split(",");
			for (String strIp : ips) {
				if (!UNKNOWN_IP.equalsIgnoreCase(strIp)) {
					ip = strIp;
					break;
				}
			}
		}
		return ip;
	}
}
```

在启动类中增加获取该工具类的方法：

```java
@RestController
@RequestMapping
@SpringBootApplication
public class DemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

	@GetMapping("/ip")
	public String getIp(HttpServletRequest request) {
		return RequestUtils.getIpAddress(request);
	}
}
```

然后直接将应用打 `jar` ：

```
$ mvn clean package
...
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 32.288 s
[INFO] Finished at: 2018-12-15T17:21:22+08:00
[INFO] Final Memory: 34M/169M
[INFO] ------------------------------------------------------------------------

D:\IntelliJIDEA\workspace\MinGRn\docker-test
$ ls target\
docker-web-0.0.1.jar ...
```

在服务器下创建一个 `docker-file` 文件夹将该 jar 上传到该文件夹下：

```
$ mkdir docker-file
$ cd docker-file/
$ rz
$ ls
docker-web-0.0.1.jar
```

# 编写 Dockerfile

`docker-web-0.0.1.jar` 成功上传至文件夹后，再在该文件夹下去创建 `Dockerfile` 文件，内容如下所示：

```
# Version 1 - EDITION 1
# Author MinGRn

# Base Image
FROM ifkeeper/jvm8:v1.0.0

MAINTAINER MinGRn <MinGRn97@gmail.com>

# Work dir
WORKDIR /app

# Copy current files to /app
COPY . /app

# Command
ENTRYPOINT ["java", "-jar", "/app/docker-web-0.0.1.jar", "--server.port=80"]
```

现在可以看到该文件夹下只有这两个文件：

```
$ ls
Dockerfile  docker-web-0.0.1.jar
```

现在执行构建镜像命令：

```
$ docker build -t <name>:<tag> .
```

命令示例如下：

```
$ docker build -t ifkeeper/web-test:v1.0.3 .

Sending build context to Docker daemon  18.86MB
Step 1/5 : FROM ifkeeper/jvm8:v1.0.0
v1.0.0: Pulling from ifkeeper/jvm8
a02a4930cb5d: Already exists 
3c364b7660c3: Already exists 
Digest: sha256:dc3c695f49433ddbc8b821bd5b0019b370ff56d338f8885c6b336780fcb491bb
Status: Downloaded newer image for ifkeeper/jvm8:v1.0.0
 ---> 9ef7f38f2bf1
Step 2/5 : MAINTAINER MinGRn <MinGRn97@gmail.com>
 ---> Running in f71fcd060fb1
Removing intermediate container f71fcd060fb1
 ---> 21835cef93fc
Step 3/5 : WORKDIR /app
 ---> Running in 7bac3b31f358
Removing intermediate container 7bac3b31f358
 ---> 1e357b3f6ae3
Step 4/5 : COPY . /app
 ---> 5e04ef148b44
Step 5/5 : ENTRYPOINT ["java", "-jar", "/app/docker-web-0.0.1.jar", "--server.port=80"]
 ---> Running in e9fa1798a023
Removing intermediate container e9fa1798a023
 ---> 930517912f6a
Successfully built 930517912f6a
Successfully tagged ifkeeper/web-test:v1.0.3
```

提示已经成功，现在查看镜像：

```
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
ifkeeper/web-test   v1.0.3              930517912f6a        About a minute ago   602MB
```

可以看到大小为 `602M`。

# 运行容器

现在就可以使用 `docker run <image_id>` 命令运行将该镜像增加读写层成为一个容器，并运行。关于该命令后续进行说明。

运行示例：

```
$ docker run -p "80:80" 930517912f6a

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v2.1.1.RELEASE)
```

- `-p`：该命令是进行端口映射，将容器端口 80 映射到主机 80 端口。这样通过访问该主机 80 端口即可访问该应用。如果想要 4000 端口如：`-p "4000:80"`

打开浏览器发送请求获取ip：`192.168.31.130/ip` 成功返回客户端ip即表示该应用构建成功。

另外，可以在命令中加 `-d` 表示在后台运行。如：

```
$ docker run -p "80:80" -d 930517912f6a
```

如果想要查看正在运行的容器，可以使用该命令：`docker ps`，如下所示：

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                NAMES
192f2031ad54        930517912f6a        "java -jar /app/dock…"   7 minutes ago       Up 2 seconds        0.0.0.0:80->80/tcp   brave_dewdney
```

如果想要查看全部容器（包括非运行中的容器）需要在该命令加 `-a`，如下所示：

```
$ docker ps -a
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS                       PORTS                NAMES
192f2031ad54        930517912f6a               "java -jar /app/dock…"   8 minutes ago       Up 57 seconds                0.0.0.0:80->80/tcp   brave_dewdney
2372f9a88fea        ifkeeper/web-test:v1.0.2   "java -jar /app/dock…"   2 hours ago         Exited (143) 9 minutes ago                        web_api.13.u2gptpndccc3scj7dtz17477n
ece9e6b032ad        ifkeeper/web-test:v1.0.2   "java -jar /app/dock…"   2 hours ago         Exited (143) 9 minutes ago                        web_api.2.tj3vcn8s00x2ydwxitxi81dwo
6d61c5f66b94        ifkeeper/web-test:v1.0.2   "java -jar /app/dock…"   2 hours ago         Exited (143) 9 minutes ago                        web_api.5.yh5u9wfjgo67lbmsc7nsludf8
```

如果想要停止正在运行的容器可以使用 `docker container stop <container_id>` 命令。

# 上传镜像至 DockerHub

到此，第一个应用就构建成功了。可以看到，最主要的是构建一个镜像。该镜像在我们本地成功运行后，就可以进行交付。因为该镜像中已经包含了 jvm 运行时所需要的环境，因此可以做到 **一次构建，随处运行** 。

现在我们就将该镜像上传至 Docker Hub，当然，你也可以上传至自己的私有 Hub。以后再想运行该应用，直接拉去下来运行即可。

上传到 DockerHub 首先要进行登录：

```
$ docker login
```

然后输入账号密码即可。登录成功后直接将镜像上传至 DockerHub。

示例如下：

```
$ docker push ifkeeper/web-test:v1.0.3

The push refers to repository [docker.io/ifkeeper/web-test]
65d87db336f8: Pushed 
b5067df977d6: Pushed 
2c218a57b7e7: Layer already exists 
071d8bd76517: Layer already exists 
v1.0.3: digest: sha256:ea42233c77592f0395f8e1aef7c1e2e14d204347f2d4ff853a796d946ea1c5d0 size: 1161
```
