#!/bin/sh

set -x
set -e

test -e zstd/lib/libzstd.a || ./install-zstd.sh
cd slow5lib && make clean && make -j slow5_mt=1 zstd_local=../zstd/lib/  && cd ..
gcc -Wall -O2 -g -I slow5lib/include/ -o slow5_sequential sequential.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a  -lm -lz -fopenmp
gcc -Wall -O2 -g -I slow5lib/include/ -o slow5_random random.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp
