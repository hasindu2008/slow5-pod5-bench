#!/bin/sh

die() {
    echo "$1" 1>&2
    exit 1
}

export CC=gcc-10
export CXX=g++-10

$CC --version || die "gcc-10 not found"
$CXX --version || die "g++-10 not found"

test -e pod5_format/lib/libpod5_format.so || die "pod5_format not found"

$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib/libpod5_format.so -lm -lz -fopenmp -lpthread || die "Failed to build pod5_sequential"
$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_random random.cpp pod5_format/lib/libpod5_format.so -lm -lz -fopenmp -lpthread || die "Failed to build pod5_random"
