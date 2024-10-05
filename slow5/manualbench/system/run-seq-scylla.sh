#!/bin/bash

# edit the following
export MACHINE=scylla
export FILE=PGXXXX230339
export SOURCE_DIR=/home/hasindu/hasindu2008.git/slow5-pod5-bench/slow5
export BLOW5=/data/hasindu/slow5-pod5-bench-data/PGXXXX230339_reads_zstd-sv16-zd.blow5

./manualbench/system/linux-seq.sh
