#!/bin/bash

# edit the following
export MACHINE=aws-s3
export FILE=PGXXXX230339
export SOURCE_DIR=~/slow5-pod5-bench/slow5
export BLOW5=~/s3/PGXXXX230339_reads_zstd-sv16-zd.blow5

./manualbench/system/linux-seq.sh
