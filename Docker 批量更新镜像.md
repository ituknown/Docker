
参考：

https://docs.docker.com/engine/cli/formatting/


```bash
docker images --format "{{.Repository}}:{{.Tag}}" | xargs -L1 docker pull
```