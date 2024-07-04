#!/bin/bash

die()
{
	echo "$1" 1>&2
	exit 1
}

benchmark(){
	echo "POD5 IO"
	for i in $(seq 1 5); do
		echo "Iteration $i"
		./run_rand.sh ${POD5} ${LIST} ${THREADS} 1000 io &> rand_pod5_${MACHINE}_${FILE}_${THREADS}_io_${i}.log
	done

	echo "POD5 MMAP"
	for i in $(seq 1 5); do
	echo "Iteration $i"
		./run_rand.sh ${LIST} ${LIST} ${THREADS} 1000 mmap &> rand_pod5_${MACHINE}_${FILE}_${THREADS}_mmap_${i}.log
	done
}

THREADS=$(nproc)
MACHINE=gtgpu-ssd
FILE=PGXXXX230339

SOURCE_DIR=/data/hasindu/hasindu2008.git/slow5-pod5-bench/pod5
SRC_POD5=/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5
SRC_LIST=/home/hasindu/scratch/hg2_prom_lsk114_5khz/500k.list
POD5=/data/tmp/PGXXXX230339_reads.pod5
LIST=/data/tmp/500k.list

cd ${SOURCE_DIR} || die "cd fail"
echo "Copying pod5 file"
test -e ${POD5} || cp ${SRC_POD5} ${POD5} || die "cp fail"
cp ${SRC_LIST} ${LIST} || die "cp fail"

benchmark

echo "done"
#rm /data/tmp/PGXXXX230339_reads.pod5 || die "rm fail"
rm ${LIST}|| die "rm fail"

