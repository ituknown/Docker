
```bash
docker images --format "{{.Repository}}:{{.Tag}}" | xargs -L1 docker pull
```