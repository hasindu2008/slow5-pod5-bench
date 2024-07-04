#!/bin/bash

die()
{
	echo "$1" 1>&2
	exit 1
}

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/pod5 || die "cd fail"

THREADS=$(nproc)
POD5=/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5

echo "POD5 IO"
for i in $(seq 1 5); do
	echo "Iteration $i"
	./run_seq.sh ${POD5} ${THREADS} io &> gtgpu-nfs_PGXXXX230339_reads_${THREADS}_io_${i}.log
done

echo "POD5 MMAP"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_seq.sh ${POD5} ${THREADS} mmap &> gtgpu-nfs_PGXXXX230339_reads_${THREADS}_mmap_${i}.log
done

echo "done"

