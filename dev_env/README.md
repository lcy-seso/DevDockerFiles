build the docker image

```bash
docker build -t dev .
```

run the docker container

```bash
docker run -it -v /home/yincao/codes/:/workspace/ dev
```

```bash
git config --global --add safe.directory '*'
```
