#!/bin/sh

set -x
set -e

g++ -Wall -O2 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -fopenmp -lpthread
g++ -Wall -O2 -g -I pod5_format/include -I cxxpool/src -o pod5_random random.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -fopenmp -lpthread
