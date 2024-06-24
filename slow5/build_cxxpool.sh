#!/bin/sh

set -x
set -e

test -e zstd/lib/libzstd.a || ./install-zstd.sh
export CC=gcc-10
export CXX=g++-10
cd slow5lib && make clean && make -j CC=$CC slow5_mt=1 zstd_local=../zstd/lib/  && cd ..
$CXX -Wall -O3 -g -I slow5lib/include/ -I ../pod5/cxxpool/src -o slow5_sequential_cxxpool sequential_cxxpool.cpp slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lpthread
