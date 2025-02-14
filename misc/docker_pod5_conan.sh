#!/bin/sh
# Compile pod5 on debian:bookworm-slim docker image
# Steps:
# git clone https://github.com/nanoporetech/pod5-file-format
# git -C pod5-file-format checkout 0.3.15
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

# Conan method
/usr/bin/time -vo time.out apt-get -y install python3 python3-pip python3-venv cmake git
python3 -m venv snake
/usr/bin/time -vao time.out ./snake/bin/pip3 install 'conan<2' 'setuptools_scm==7.1.0'
/usr/bin/time -vao time.out ./snake/bin/python3 -m setuptools_scm
/usr/bin/time -vao time.out ./snake/bin/python3 -m pod5_make_version
mkdir build
cd build
/usr/bin/time -vao ../time.out ../snake/bin/conan install --build=missing -s build_type=Release .. -s compiler.version=8
/usr/bin/time -vao ../time.out cmake -DENABLE_CONAN=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake ..
/usr/bin/time -vao ../time.out make

du -b Release/lib/libpod5_format.a
