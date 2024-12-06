#!/bin/sh

# edit the following
export MACHINE=android-sd
export FILE=PGXXXX230339
export SOURCE_DIR=/data/local/tmp/slow5-pod5-bench/slow5
export BLOW5=/storage/7FF2-7913/data/PGXXXX230339_reads_zstd-sv16-zd.blow5
export LIST=/storage/7FF2-7913/data/500k.list

./manualbench/system/linux-rand.sh
