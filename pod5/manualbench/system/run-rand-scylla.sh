#!/bin/bash

# edit the following
export MACHINE=scylla
export FILE=PGXXXX230339
export SOURCE_DIR=/home/hasindu/hasindu2008.git/slow5-pod5-bench/pod5
export POD5=/data/hasindu/slow5-pod5-bench-data/PGXXXX230339_reads.pod5
export LIST=/data/hasindu/slow5-pod5-bench-data/500k.list

./manualbench/system/linux-rand.sh
