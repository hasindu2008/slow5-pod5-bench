#!/bin/sh

set -x
set -e

g++ -Wall -O2 -g -I pod5_format/include -I cxxpool/src -o pod5_convert_to_pa pod5_convert_to_pa.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -fopenmp
#g++ -Wall -O2 -g -I pod5_format/include -I cxxpool/src -o pod5_convert_to_pa_rand pod5_convert_to_pa_rand.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -fopenmp
