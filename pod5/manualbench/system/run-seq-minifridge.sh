#!/bin/bash

# edit the following
export MACHINE=minifridge-ssd
export FILE=PGXXXX230339
export SOURCE_DIR=/home/hasindu/slow5-pod5-bench/pod5
export POD5=/data2/tmp/PGXXXX230339_reads.pod5

./manualbench/system/linux-seq.sh
