#!/bin/bash

# edit the following
export MACHINE=hmnat
export FILE=PGXXXX230339
export SOURCE_DIR=/mnt/d/hasindu2008.git/slow5-pod5-bench/slow5
export BLOW5=/mnt/e/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5
export LIST=/mnt/e/tmp/500k.list

./manualbench/system/linux-rand.sh
