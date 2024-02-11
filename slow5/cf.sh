#!/bin/sh
# config file

export ZSTD=zstd # path to zstd repo
export ZSTD_INC=$ZSTD/lib
export ZSTD_VER=1.5.4
export ZSTD_STATIC=$ZSTD/lib/libzstd.a
export ZSTD_SHARED=$ZSTD/lib/libzstd.so.$ZSTD_VER

export TOOLS=slow5tools # path to slow5tools repo
export TOOLS_URL=https://github.com/hasindu2008/slow5tools
export TOOLS_COMMIT=8a366bf6dffe0c94fd0ec148cca22f09e47c31e5 # latest upstream vbz
export TOOLS_LIB_COMMIT=8efc1f704f864ba5e29c75ffa85ebb248007bb46 # latest upstream vbz
export TOOLS_EXEC=$TOOLS/slow5tools

export LIB=slow5lib
export LIB_COMMIT=a90d45cf0aa53a32205f1fbadb8b8b1a132cd085 # latest local bench
export LIB_INC=$LIB/include
export LIB_STATIC=$LIB/lib/libslow5.a

export REC_PRESS=zstd # record compression
export SIG_PRESS=svb16-zd # signal compression

export RAND=slow5_random
export SEQ=slow5_sequential
export SEQ_CXX=slow5_sequential_cxxpool
export CCFLAGS='-Wall -O2 -g'
export LDFLAGS='-lm -lz -fopenmp'
export RUN_CXX= # set to non-empty to run SEQ_CXX in experiments
