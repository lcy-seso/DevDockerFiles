## Usage

### Build the docker image

build the docker image

```bash
docker build -t dev .
```

run the docker container

```bash
docker run --gpus all -it -v /home/yincao/codes/:/workspace/ dev
```

### Or pull the docker image

pull the docker image

```bash
docker pull ying55/dev-env:v0.1
```

run the docker container

```bash
docker run --gpus all -it -v /home/yincao/codes/:/workspace/ ying55/dev-env:v0.1
```

### Some known issues

- You may need to run the following git command to allow sharing across users in the container.

  ```bash
  git config --global --add safe.directory '*'
  ```

- If you used `setup.sh`, after running it, start vim and execute these commands to complete the setup:

  ```
  :PlugInstall
  :CocInstall coc-json coc-python coc-julia
  ```
