
在 Docker 中，`<none>` 标签的镜像就是 dangling 镜像，通常是旧的或临时构建残留。示例：

```bash
$ docker image ls -a
REPOSITORY                        TAG               IMAGE ID       CREATED             SIZE
<none>                            <none>            5c06d8bdc704   About an hour ago   75.9MB
debian                            bookworm-slim     74a962b7e6e5   2 days ago          74.8MB
debian                            stable            678d881964f7   2 days ago          120MB
debian                            bookworm          4ffc839c7aa5   2 days ago          117MB
debian                            stable-slim       78e1977f41de   2 days ago          78.6MB
postgres                          17.6              3fe059c96160   5 days ago          453MB
mysql                             8.0.43            94753e67a0a9   7 days ago          780MB
rust                              1.90.0-bookworm   b5650936b58b   12 days ago         1.54GB
postgres                          <none>            1b0dba5f47c1   3 weeks ago         454MB
gcr.io/distroless/base-debian12   latest            a1eeb18eb59c   N/A                 20.8MB
gcr.io/distroless/java17          latest            347571205626   N/A                 226MB
gcr.io/distroless/cc-debian12     latest            a0d9435c3978   N/A                 23.6MB
gcr.io/distroless/java21          latest            a239484ba741   N/A                 192MB
gcr.io/distroless/java11          latest            42b1763c76e2   N/A                 209MB
```

其中 5c06d8bdc704 就是 dangling 镜像。

- 只查看 `<none>` 镜像

```bash
docker images -f dangling=true
```

- 删除 `<none>` 镜像

```bash
docker rmi $(docker images -f dangling=true -q)
```

说明：

1. `docker images -f dangling=true -q`：获取所有 `<none>` 镜像的 ID

2. `docker rmi`：删除这些镜像

| **Note**                               |
| :------------------------------------- |
| 如果某个 `<none>` 镜像被容器使用，会删除失败，需要先删除相关容器。 |

也可以使用下面方式删除 dangling 镜像：

Linux / macOS：

```bash
docker images -f dangling=true -q | xargs docker rmi -f
```

Windows PowerShell：

```powershell
docker images -f dangling=true -q | ForEach-Object { docker rmi $_ }
```