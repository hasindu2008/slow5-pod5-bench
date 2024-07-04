#!/bin/bash

die()
{
	echo "$1" 1>&2
	exit 1
}

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5 || die "cd fail"

THREADS=$(nproc)
BLOW5=/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5
LIST=/home/hasindu/scratch/hg2_prom_lsk114_5khz/500k.list

echo "BLOW5 C"
for i in $(seq 1 5); do
	echo "Iteration $i"
	./run_rand.sh ${BLOW5} ${LIST} ${THREADS} 1000 c &> gtgpu-nfs_PGXXXX230339_reads_zstd-sv16-zd_${THREADS}_1000_c_${i}.log
done

echo "BLOW5 CXX"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_rand.sh ${BLOW5} ${LIST} ${THREADS} 1000 cxx &> gtgpu-nfs_PGXXXX230339_reads_zstd-sv16-zd_${THREADS}_1000_cxx_${i}.log
done

echo "done"

