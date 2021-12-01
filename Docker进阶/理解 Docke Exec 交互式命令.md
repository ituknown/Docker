# 前言

使用 Docker 部署服务虽然简单，但是我们经常会有某种需要进入容器。而想要进入容器 `docker exec` 命令是必不可少的。这篇博文呢，就简单聊聊 `docker exec` 命令的使用。

Docker 对 exec 命令的解释是：Run a command in a running container（说白话就是在容器中运行一个命令），如下：

```bash
$ docker --help | grep exec
  exec        Run a command in a running container
```

另外，exec 还有几个重要的可选参数。该命令的使用语法如下：

```bash
$ docker exec [-itdeuw] container COMMAND [ARG...]
```

选项和参数：

```
-i：以交互式命令运行。简单的说就是保持打开 STDIN 标准输入流用于输入数据。
-t：分配一个 TTY 终端。这个很好理解，我们使用 ssh 远程登录服务器时其实就是分配一个 TTY 环境（Linux 默认开启的 TTY 有 TTY1 ~ TTY6）。
-d：在后台运行命令
-e：用于设置环境变量（不推荐这么玩）
-w：指定一个工作目录用于替代容器中已有的工作目录（不推荐这么玩）
-u：指定一个登录用户（很少使用）
```


上面的参数选项中，`-i` 和 `-t` 是最重要的，也是这里要重点说明的。`container` 指的就是具体的运行状态的容器，可以是容器的 ID 也可以使用容器的名称。而 `COMMAND` 就是我们要执行的具体命令，这也是我们使用 `docker exec` 的原因。最后的 `ARG` 则是 `COMMAND` 的可选参数了。这些会在下面进行详细介绍。


| **Note**                                                     |
| :----------------------------------------------------------- |
| 上面 `exec` 命令语法及可选参数可以直接使用 `docker exec --help` 命令查看。另外，`docker exec` 只能用于运行状态的容器，已停止的容器是无法使用的！ |



# 理解交互式运行参数 `-it`

使用 `docker exec` 在容器中交互式运行命令的主要参数是 `-i` 和 `-t`，在使用时参数可以进行合并，即：`-it`。

**交互式参数：`-i`：**

`-i` 可以理解为 `INPUT IO`，这个是由键盘输入的数据。在 Linux 中主要有三种 IO，分别是标准输入`STDIN`、标准输出`STDOUT` 以及标准错误`STDERR`。

如果你对 Linux 的这三种 IO 了解的话那么会对这个 `-i` 参数就一目了然了，即使不了解也没关系，反正你记住 `-i` 参数就是打开一个 STDIN 用于我们输入数据即可。

**分配 TTY 参数：`-t`：**

`-t` 是分配 tty 的意思，可以简单的理解为就是打开一个“伪终端”。

这个大家都不陌生，而且在平时工作中经常会用到。想一下我们是如何登录 Linux 服务器的？是不是使用 ssh 进行远程登录的？

登录完成后就能输入 Linux 的命令，当连续按两次 TAB 键居然还有命令补全提示。之所以会这样的原因就是当我们使用用户登录 Linux 服务器时，服务器会将当前用户的操作环境（涉及到环境变量和 Shell）数据 “响应” 给客户端。

当然仅仅发送操作环境数据是不行的，因为我们还需要一个输入终端，这个就是 TTY。当这两个都响应给客户端后我们才能直接在客户端 TTY 中操作服务器数据，而且在使用时你会发现跟直接操作服务器一样丝滑。

这里要补充一个小知识点就是：Linux 服务器启动时默认会分配 6 个 TTY（TT1~TT6）。而到底有多少个 TTY 可以使用下面的命令查看：

```bash
$ ls /dev/tty*
```

--

所以这么一看 `docker exec -it` 就用打开一个 STDIO，并从容器中分配一个 TTY 供我们使用，现在是不是彻底理解了？

现在从新来看下 `docker exec` 语法，这回指定参数为 `-it`，如下：


```bash
$ docker exec -it container COMMAND [ARG...]
```

现在再回头看这个语法唯一还不清楚的就是 `COMMAND` 参数了，这个就是具体的命令。还是以 ssh 登录服务器为例，登录服务器之后我们是不是可以执行某个命令？这个语法中的 `COMMAND` 就是你登录服务器之后要执行的命令，`ARG` 是该命令可以额外指定的参数。

`docker exec -it` 与 ssh 唯一的区别是仅仅只能执行一次命令，当命令执行完成后就自动退出 TTY，这个似乎与 `su` 的 `-c` 参数有点类似。好好去想一下吧，接下来来看下具体的演示示例：


# 运行一个容器

这里我们就以 `ubuntu:20.4` 镜像为例演示下交互式运行：

**运行容器：**

```bash
$ sudo docker run -itd --rm --name ubuntu ubuntu:20.04 /bin/bash
```

**查看容器运行状态：**

```bash
$ sudo docker container ls
CONTAINER ID   IMAGE          COMMAND       CREATED         STATUS         PORTS     NAMES
0ab7c5e1a448   ubuntu:20.04   "/bin/bash"   9 seconds ago   Up 8 seconds             ubuntu
```

一个基于 Ubuntu 的容器就运行好了，那来演示下交互式命令：

# 进入容器

docker 交互式命令最基础的使用就是进入一个运行状态的容器中，如下：

```bash
$ sudo docker exec -it ubuntu /bin/bash
```

之后你会发现你的终端变成了如下形式，这说明我们是以 root 用户登录到 ubuntu 容器，这个稍后会进行说明。现在我们就可以执行任何 Linux 命令了：

```bash
root@0ab7c5e1a448:/#
```

等等！不是说 `docker exec -it` 执行一条命令就自动退出 TTY 环境吗？为什么我们可以一直执行呢？

注意看我们进入容器后执行的命令：`/bin/bash`。这是 fork 一个 bash 环境的意思。

这就不得不提一下 bash 这个命令了，当我们在 TTY 终端执行 bash 命令时其实就是基于当前操作环境 Fork 一个子进程的意思，子进程会完全继承父进程的操作环境数据。

这里简单说下，当我们在当前 Shell 环境执行 bash 命令时，其实就是 fork 了一个子进程，如下：

![bash-fork-1638083272OKb1FY](http://docker-media.knowledge.ituknown.cn/Advanced/DockerExec/bash-fork-1638083272OKb1FY.png)

之后我们执行的所有命令都是在子进程中执行的，此时的父进程我们可以理解为处于 Sleep 状态，直到我们输入 exit 之后才会返回到父进程。

这个你可以很容易的就能演示出来，比如你使用 ssh 登录到服务器：

```bash
$ ssh user@serverhost
```

登录成功之后我们输入 exit 命令就会退出 TTY。但是如果登录之后先执行一次 bash 命令，想要退出 TTY 就需要输入两次 exit 才行。看下下面的演示：

```bash
# 登录到服务器
$ ssh ubuntu
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-40-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

0 updates can be applied immediately.

Your Hardware Enablement Stack (HWE) is supported until April 2025.
Last login: Sun Nov 28 14:13:51 2021 from 192.168.1.4

# 此时成功登录服务器

# 先输入 bash 命令 fork 子进程
$ bash

# 第一次 exit
$ exit
exit  <== 并没有真正的退出 TTY, 仅仅是退出子进程

# 第二次 exit
$ exit
logout
Connection to 192.168.1.5 closed.  <== 第二次才真正的 退出 TTY
```

现在理解为什么下面这条命令执行一次命令后没有退出 TTY 的原因了吗？

```bash
$ sudo docker run -itd --rm --name ubuntu ubuntu:20.04 /bin/bash
```

接下来我我们就可以在容器中执行任何命令了，因为这是一个基于 Ubuntu 的环境，虽然是简易版的，但是并不妨碍你执行 Linux 的任何命令。即使命令不存在你也可以进行安装了，这就是为什么容器这么受欢迎的原因！

下面来看下创建一个 README 文件：

```bash
# 进入容器
$ sudo docker exec -it ubuntu /bin/bash
root@0ab7c5e1a448:/#
# 创建 README 文件
root@0ab7c5e1a448:/# touch README
# 查看文件
root@0ab7c5e1a448:/# ls | grep README
README
root@0ab7c5e1a448:/#
```

再比如我想要查看容器的环境变量，在 TTY 中输入 Linux 的 env 命令就好了：

```bash
root@0ab7c5e1a448:/# env
HOSTNAME=0ab7c5e1a448
PWD=/
HOME=/root
TERM=xterm
SHLVL=1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
_=/usr/bin/env
root@0ab7c5e1a448:/#
```


# 交互式执行命令

前面呢，介绍了如何进入容器以及为什么 /bin/bash 命令之后完成后没有退出 TTY。现在呢，就来只执行一条命令来看看。

先退出容器环境，输入 exit 命令即可！

有了前面的基础这里就比较简单了，下面来看下演示示例：

**查看容器的环境变量：**

```bash
$ sudo docker exec -it ubuntu env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=0ab7c5e1a448
TERM=xterm
HOME=/root
```

| Note                                                   |
| :----------------------------------------------------- |
| 注意看 `HOME` 的值是 `/root`，说明这是一个 root 用户。 |


**创建一个文件：**

```bash
$ sudo docker exec -it ubuntu touch HelloWord.txt

# 查看创建的文件
$ sudo docker exec -it ubuntu ls | grep txt
HelloWord.txt
```


# 指定交互用户

有没有发现前面交互式命令使用的用户都是 root？我们其实可以使用 `-u` 指定具体的交互用户：

```bash
$ sudo docker exec -it -u [uid|uname] container COMMAND [ARG...]
```

使用 `-u` 参数指定容器中具体用户的 uid 或者 username 就好了，来看下：

首先呢，进入容器创建一个 webuser 用户：

```bash
# 进入容器
$ sudo docker exec -it ubuntu /bin/bash

# 查看用户是否存在
root@0ab7c5e1a448:/# grep -v webuser /etc/passwd

# 创建 webuser 用户
root@0ab7c5e1a448:/# useradd webuser

# 查看 webuser 信息
root@0ab7c5e1a448:/# id webuser
uid=1000(webuser) gid=1000(webuser) groups=1000(webuser)
```

现在呢，我们就在容器中创建好了一个 webuser 用户，uid 为 1000。现在就使用该用户做交互式执行吧：

```bash
$ sudo docker exec -it -u 1000 ubuntu /bin/bash
webuser@0ab7c5e1a448:/$ <== 变成了 webuser 用户了
```

当然了，因为容器本身就是与操作系统资源隔离的，是不会感染到操作系统的，除非 Docker 有漏洞。所以没有必要去创建一个新用户进行交互。


# 设置环境变量

设置环境变量虽然很有用，单不推荐这种玩法，了解一下即可。先来看下当前容器的环境变量：

```bash
$ sudo docker exec -it ubuntu env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=0ab7c5e1a448
TERM=xterm
HOME=/root
```

现在来使用 `-e` 参数设置一个新的环境变量：

```bash
$ sudo docker exec -e "AUTHOR=MINGRN" ubuntu env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=0ab7c5e1a448
AUTHOR=MINGRN  <== 在这呢
HOME=/root
```

当然了，在实际中是不推荐这么玩的。

--

好了，完结撒花🎉🎉🎉~