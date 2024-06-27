#!/bin/sh

set -x
set -e

export CC=gcc-10
export CXX=g++-10

$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -fopenmp -lpthread
$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_random random.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -fopenmp -lpthread
