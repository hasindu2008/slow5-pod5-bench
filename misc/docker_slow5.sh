#!/bin/sh
# Compile slow5 on debian:bookworm-slim docker image
# Steps:
# git clone https://github.com/hasindu2008/slow5lib
# git -C slow5lib checkout bench
# screen
# docker run -it debian:bookworm-slim
# CTRL-a d
# docker cp docker_slow5.sh CONTAINER:/root/
# docker cp slow5lib CONTAINER:/root/
# screen -r
# cd
# ./docker_slow5.sh > docker_slow5.out 2>&1
# CTRL-a d
# docker cp CONTAINER:/root/slow5lib/time.out .
# docker cp CONTAINER:/root/docker_slow5.out .

set -e

apt-get update
apt-get -y install time
cd slow5lib
/usr/bin/time -vo time.out apt-get -y install zlib1g-dev libzstd-dev make gcc
/usr/bin/time -vao time.out make zstd=1
du -b lib/libslow5.so
