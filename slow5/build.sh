#!/bin/sh

set -x
set -e

cd slow5lib && make clean && make -j zstd=1 slow5_mt=1 && cd ..
gcc -Wall -O2 -g -I slow5lib/include/ -o slow5_sequential sequential.c slow5lib/lib/libslow5.a -lm -lz -lzstd -fopenmp
gcc -Wall -O2 -g -I slow5lib/include/ -o slow5_convert_to_pa_rand slow5_convert_to_pa_rand.c slow5lib/lib/libslow5.a -lm -lz -lzstd -fopenmp
