#!/bin/bash

die()
{
	echo "$1" 1>&2
	exit 1
}

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/pod5 || die "cd fail"
echo "Copying slow5 file"
cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 /data/tmp/PGXXXX230339_reads.pod5 || die "cp fail"
cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/500.list /data/tmp/500.list || die "cp fail"

THREADS=$(nproc)

echo "POD5 IO"
for i in $(seq 1 5); do
	echo "Iteration $i"
	./run_rand.sh /data/tmp/PGXXXX230339_reads.pod5 /data/tmp/500.list ${THREADS} 1000 io &> gtgpu-ssd_PGXXXX230339_reads_${THREADS}_io_${i}.log
done

echo "POD5 MMAP"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_rand.sh /data/tmp/PGXXXX230339_reads.pod5 /data/tmp/500.list ${THREADS} 1000 mmap &> gtgpu-ssd_PGXXXX230339_reads_${THREADS}_mmap_${i}.log
done

echo "done, remove the file"
rm /data/tmp/PGXXXX230339_reads.pod5 || die "rm fail"
rm /data/tmp/500.list || die "rm fail"

