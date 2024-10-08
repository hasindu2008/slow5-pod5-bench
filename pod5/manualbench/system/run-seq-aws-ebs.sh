#!/bin/bash

# edit the following
export MACHINE=aws-ebs
export FILE=PGXXXX230339
export SOURCE_DIR=~/slow5-pod5-bench/pod5
export POD5=/ebs/data/PGXXXX230339_reads.pod5

./manualbench/system/linux-seq.sh
sudo poweroff
