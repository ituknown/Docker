# 安装准备

|**NOTE**|
|:------|
| Docker 官网提供了各发行版安装教程，非常详细。本文仅仅是为了记录傻瓜式的安装命令，没有实际意义。|

在安装之前需要先确定主机上是否安装过 Docker，如果不确定机器是否已经安装过 Docker 可以直接 `docker --version` 命令或者看看在 `/var/lib` 有没有 `docker` 文件夹，如果有的话说明已经安装过 `docker` 。

要想重新安装需要先进行卸载当前主机上的 `docker` 。

|**注意**|
|:---|
|在卸载之前尽可能的将必要的 Docker 数据进行备份，比如容器镜像等数据。防止安装新版本后这些数据被误删或不可用等问题。|

确定主机上已经安装过 Docker 后需要执行如下命令进行卸载旧版 Docker ，如果没有安装过就没必要去执行该命令了。

- Debian/Ubuntu 系列卸载命令

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

- RHEL/CentOS 系列卸载命令

```bash
sudo yum remove docker \
docker-client \
docker-client-latest \
docker-common \
docker-latest \
docker-latest-logrotate \
docker-logrotate \
docker-engine
```

# Debian 系列安装 Docker

**如果你的使用的是 Ubuntu ，只需要将下列命令中的 debian 替换为 ubuntu 即可。**

## 官方安装

没啥要说明的，直接拷贝粘贴就好~

```bash
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```

## 使用中科大镜像站安装

使用镜像站的唯一原因是 Docker 是国外的，直接使用官方安装可能会很慢，所以个人都是使用国内镜像站。

国内的镜像站比较多，比较有名的就是[中科技](https://mirrors.ustc.edu.cn)、[清华](https://mirrors.tuna.tsinghua.edu.cn/)、网易以及阿里云等镜像站。**个人用的比较多的就是中科技镜像站，好评不解释。**

```bash
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.ustc.edu.cn/docker-ce/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```

# RHEL 系列安装 Docker

## 官方安装

```bash
yum install -y yum-utils

sudo yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y docker-ce docker-ce-cli containerd.io
```

# Docker 系统命令

## 启动 Docker 服务

```bash
systemctl start docker
```

## 停止 Docker 服务

```bash
systemctl stop docker
```

## 设置开机自启

```bash
systemctl enable docker
```

## 关闭开机自启

```bash
systemctl disable docker
```

# 测试 Docker

现在就可以使用 Docker 运行一个简单的容器来进行测试 Docker ：

```bash
$ docker run hello-world
```

输出如下信息标识成功运行：
```
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
```

# 安装 docker-compose

`docker-compose` 安装起来就比较简单了，只需要如下两个个命令即可：

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.6.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

注意，curl 链接中的 v2.6.0 是要安装的 docker-compose 版本，当前最新版本是 v2.6.0。可以在 [Github releases](https://github.com/docker/compose/releases) 找到所有的版本，比如要安装 v1.24.1 版本，只需要替换对应的链接即可：

```bash
https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)
```

安装完成后可以使用下面的命令进行验证：

```bash
# v2.0 及以上版本
$ docker compose version

# v2.0 以下版本
$ docker-compose version
```

如果你是 ubuntu 用户的话安装 docker-compose 就更简单了，直接使用下面的命令即可：

```bash
sudo apt-get update -y && sudo apt-get install -y python3-pip curl vim git moreutils
pip3 install --upgrade pip
pip install docker-compose
```