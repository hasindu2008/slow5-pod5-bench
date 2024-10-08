#!/bin/bash

# edit the following
export MACHINE=aws-ebs
export FILE=PGXXXX230339
export SOURCE_DIR=~/slow5-pod5-bench/slow5
export BLOW5=/ebs/data/PGXXXX230339_reads_zstd-sv16-zd.blow5
export LIST=/ebs/data/500k.list

./manualbench/system/linux-rand.sh
sudo poweroff
