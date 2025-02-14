#!/bin/sh
# Compile pod5 on debian:bookworm-slim docker image
# Steps:
# git clone https://github.com/nanoporetech/pod5-file-format
# git -C pod5-file-format checkout 0.3.10
# git submodule update --init --recursive
# sed -i 's/Flatbuffers/FlatBuffers/' pod5-file-format/c++/CMakeLists.txt
# screen
# docker run -it debian:bookworm-slim
# CTRL-a d
# docker cp docker_pod5.sh CONTAINER:/root/
# docker cp pod5-file-format CONTAINER:/root/
# screen -r
# cd
# ./docker_pod5.sh > docker_pod5.out 2>&1
# CTRL-a d
# docker cp CONTAINER:/root/pod5-file-format/time.out .
# docker cp CONTAINER:/root/docker_pod5.out .

set -e

apt-get update
apt-get -y install time
cd pod5-file-format

# APT method
/usr/bin/time -vo time.out apt-get -y install ca-certificates lsb-release wget
/usr/bin/time -vao time.out wget "https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb"
/usr/bin/time -vao time.out apt-get -y install "./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb"
/usr/bin/time -vao time.out apt-get update
/usr/bin/time -vao time.out apt-get -y install libarrow-dev libflatbuffers-dev libzstd-dev cmake libboost-dev libboost-filesystem-dev python3-setuptools-scm python3-setuptools git
/usr/bin/time -vao time.out python3 -m setuptools_scm
/usr/bin/time -vao time.out python3 -m pod5_make_version
mkdir build
cd build
/usr/bin/time -vao ../time.out cmake ..
/usr/bin/time -vao ../time.out make

du -b c++/libpod5_format.a
