1. build docker image

   ```bash
   docker build -t cuda_dev -f dev_env/Dockerfile .
   ```

1. run docker container

   ```bash
   docker run --gpus all -it cuda_dev
   ```

1. docker delete a ***container***

   ```bash
   docker rm -f cuda_dev
   ```

1. docker image delete

   ```bash
   docker rmi cuda_dev
   ```

1. docker **container list**

   A container is runnable instance of an image.

   When you want to delete a docker image, but if there is a running container from the image, you can use the following command to list all containers, delete the container first.

   ```bash
   docker ps -a
   ```

1. docker image list

   ```bash
   docker images
   ```

1. docker run with volume

   ```bash
   docker run -it -v /home/yincao/codes/:/workspace/ dev
   ```

To see available versions of a package without having to install an external tool, use `apt-cache madison`:

```bash
apt-cache madison cmake
```
