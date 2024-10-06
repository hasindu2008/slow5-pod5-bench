#!/bin/bash

# edit the following
export MACHINE=minifridge-ssd
export FILE=PGXXXX230339
export SOURCE_DIR=/home/hasindu/slow5-pod5-bench/pod5
export POD5=/data2/tmp/PGXXXX230339_reads.pod5
export LIST=/data2/tmp/500k.list

./manualbench/system/linux-rand.sh
