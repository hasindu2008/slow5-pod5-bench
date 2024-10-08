#!/bin/bash

# edit the following
export MACHINE=aws-lustre
export FILE=PGXXXX230339
export SOURCE_DIR=~/slow5-pod5-bench/pod5
export POD5=/fsx/data/PGXXXX230339_reads.pod5
export LIST=/fsx/data/500k.list

./manualbench/system/linux-rand.sh
sudo poweroff
