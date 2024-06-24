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
export TOOLS_LIB_COMMIT=819e525166ae69a96b5e496ffc5357b99ec98e9a # latest upstream vbz
export TOOLS_EXEC=$TOOLS/slow5tools

export LIB=slow5lib
export LIB_COMMIT=f3256b6b2aa6ba07a9c1cfddc32d68a840da3a62 # latest local bench
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
