先看下当前机器中的所有镜像信息：

```bash
$ sudo docker image ls
REPOSITORY               TAG       IMAGE ID       CREATED        SIZE
lxk0301/jd_scripts       latest    d4ad9749f323   7 weeks ago    156MB
consul                   1.9.3     f810e362b00c   4 months ago   120MB
openjdk                  8-jre     608a4320629a   4 months ago   268MB
openjdk                  8-jdk     8ca4a86e32d8   4 months ago   514MB
openjdk                  11-jre    358c25f3192f   4 months ago   286MB
openjdk                  11-jdk    1eec9f9fe101   4 months ago   628MB
adoptopenjdk/openjdk11   alpine    9e85955d5a16   5 months ago   345MB
```

# 第一种方式：借助 `xargs` 命令

如果要删除全部的镜像可以使用下面的命令：

```bash
sudo docker image ls | awk 'NR>1{print $3}' | xargs docker image rm
```

其中 `awk 'NR>1{print $3}'` 作用是取出第三列数据，而 `NR>1` 的意思是取出标题行。如果不加上该命令会将标题 `IMAGE ID` 也输出出来。

如果想要删除部分镜像的话可以使用下面的命令：

```bash
sudo docker image ls | grep image_name | awk '{print $3}' | xargs docker image rm
```

**注意：** 命令中的 image_name 就是你要删除的镜像名称。

`xagrs` 命令相当于是一个过滤器，将管道前面的输出结果封装成一个数组或集合。比如查找镜像名为 `openjdk` 的所有镜像 ID：

```bash
$ sudo docker image ls | grep openjdk | awk '{print $3}'
608a4320629a
8ca4a86e32d8
358c25f3192f
1eec9f9fe101
9e85955d5a16
```

而管道 xargs 命令就相当于将输出的结果封装成一个集合，之后直接使用 docker 删除镜像命令即可，示例：

```bash
sudo docker image ls | grep openjdk | awk '{print $3}' | xargs docker image rm
```

# 第二种方式：使用 for 循环

删除全部镜像可以使用下面的命令：

```bash
sudo for i in `docker image ls | grep image_name | awk 'NR>1{print $3}'`; do docker image rm $i; done
```

如果要删除部分的话使用下面的即可：

```bash
sudo for i in `docker image ls | grep image_name | awk '{print $3}'`; do docker image rm $i; done
```


**注意：** 命令中的 image_name 就是你要删除的镜像名称。

原理与方式一相同，仅仅是使用了一个 for 循环进行执行  `docker image rm` 命令进行删除。比如要删除镜像名为 openjdk 的所有镜像：

```bash
sudo for i in `docker image ls | grep openjdk | awk '{print $3}'`; do docker image rm $i; done
```
