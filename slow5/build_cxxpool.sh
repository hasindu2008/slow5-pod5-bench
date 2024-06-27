#!/bin/sh

die()
{
    echo "$1" 1>&2
    exit 1
}

test -e zstd/lib/libzstd.a || ./install-zstd.sh
export CC=gcc-10
export CXX=g++-10

$CC --version || die "gcc-10 not found"
$CXX --version || die "g++-10 not found"

cd slow5lib && make clean
make -j CC=$CC slow5_mt=1 zstd_local=../zstd/lib/  || die "Building slow5lib failed"
cd ..
$CXX -Wall -O3 -g -I slow5lib/include/ -I ../pod5/cxxpool/src -o slow5_sequential_cxxpool sequential_cxxpool.cpp slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lpthread
