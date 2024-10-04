#!/bin/bash

# edit the following
export MACHINE=minifridge-ssd
export FILE=PGXXXX230339
export SOURCE_DIR=/home/hasindu/slow5-pod5-bench/slow5
export BLOW5=/data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5

./manualbench/system/linux-seq.sh
