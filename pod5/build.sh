#!/bin/sh

set -x
set -e

g++ -Wall -O2 -g -I pod5_format/include -I cxxpool/src -o pod5_sequntial sequntial.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -fopenmp -lpthread
