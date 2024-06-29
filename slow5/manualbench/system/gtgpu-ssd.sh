#!/bin/bash

USAGE="usage: $0 <slow5> <thr> <batch> <c/cxx>"

die()
{
	echo "$1" 1>&2
	exit 1
}

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5 || die "cd fail"
echo "Copying slow5 file"
cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 || die "cp fail"

echo "BLOW5 C"
for i in $(seq 1 5); do
	echo "Iteration $i"
	./run_seq.sh /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 c &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_c_${i}.log
done

echo "BLOW5 CXX"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_seq.sh /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 cxx &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_cxx_${i}.log
done

echo "done, remove the file"
rm /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 || die "rm fail"

