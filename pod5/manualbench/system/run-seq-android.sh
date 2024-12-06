#!/bin/sh

# edit the following
export MACHINE=android-sd
export FILE=PGXXXX230339
export SOURCE_DIR=/data/local/tmp/slow5-pod5-bench/pod5
export POD5=/storage/7FF2-7913/data/PGXXXX230339_reads.pod5

./manualbench/system/linux-seq.sh
