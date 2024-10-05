#!/bin/bash

# edit the following
export MACHINE=gtgpu-nfs
export FILE=PGXXXX230339
export SOURCE_DIR=/data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5
export BLOW5=/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5
export LIST=/home/hasindu/scratch/hg2_prom_lsk114_5khz/500k.list

./manualbench/system/linux-rand.sh
