#!/bin/bash

test $# -eq 0 && { echo "Usage: $0 <seq/rand> <machine>"; exit 1; }

MACHINE=$2

if [ "$MACHINE" == "scylla" ]; then
    SOURCE_DIR=/home/hasindu/hasindu2008.git/slow5-pod5-bench/pod5
    DATADIR=/data/hasindu/slow5-pod5-bench-data
elif [ "$MACHINE" == "fridge" ]; then
    SOURCE_DIR=/home/hasindu/slow5-pod5-bench/pod5
    DATADIR=/data3/tmp
elif [ "$MACHINE" == "minifridge" ]; then
    SOURCE_DIR=/home/hasindu/slow5-pod5-bench/pod5
    DATADIR=/data2/tmp
elif [ "$MACHINE" == "gtgpu-nfs" ]; then
    SOURCE_DIR=/data/hasindu/hasindu2008.git/slow5-pod5-bench/pod5
    DATADIR=home/hasindu/scratch/hg2_prom_lsk114_5khz/
elif [ "$MACHINE" == "hmnat" ]; then
    SOURCE_DIR=/mnt/d/hasindu2008.git/slow5-pod5-bench/pod5
    DATADIR=/mnt/e/tmp/
elif [ "$MACHINE" == "hmlaptop" ]; then
    SOURCE_DIR=/home/hasindu/slow5-pod5-bench/pod5
    DATADIR=/data/tmp
elif [ "$MACHINE" == "xavierjet2" ]; then
    SOURCE_DIR=/home/hasindu/slow5-pod5-bench/slow5
    DATADIR=/data/hasindu/slow5-pod5-bench/data/
else
    echo "Invalid machine: $2"
    exit 1
fi

FILE=PGXXXX230339
POD5=${DATADIR}/PGXXXX230339_reads.pod5
LIST=${DATADIR}/500k.list

export MACHINE
export FILE
export SOURCE_DIR
export POD5
export LIST

if [ "$1" == "seq" ]; then
    ./manualbench/system/linux-seq.sh
elif [ "$1" == "rand" ]; then
    ./manualbench/system/linux-rand.sh
else
    echo "Invalid argument: $1"
    exit 1
fi
