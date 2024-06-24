#!/bin/sh

. ./cf.sh

set -x
set -e

test -e "$ZSTD_SHARED" || ./install-zstd.sh

make -C "$LIB" clean
make -C "$LIB" -j slow5_mt=1 zstd_local="$(readlink -f $ZSTD_INC)"

gcc $CCFLAGS -c -o result.o result.c
gcc $CCFLAGS -I "$LIB_INC" -o "$SEQ" sequential.c result.o "$LIB_STATIC" "$ZSTD_STATIC" $LDFLAGS
gcc $CCFLAGS -I "$LIB_INC" -o "$RAND" random.c result.o "$LIB_STATIC" "$ZSTD_STATIC" $LDFLAGS
