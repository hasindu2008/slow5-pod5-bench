#!/bin/sh

. ./cf.sh

set -x
set -e

test -e "$ZSTD_SHARED" || ./install-zstd.sh

make -C "$LIB" clean
make -C "$LIB" -j slow5_mt=1 zstd_local="$(readlink -f $ZSTD_INC)"

g++ $CCFLAGS -I "$LIB_INC" -I ../pod5/cxxpool/src -o "$SEQ_CXX" sequential_cxxpool.cpp "$LIB_STATIC" "$ZSTD_STATIC" $LDFLAGS -lpthread
