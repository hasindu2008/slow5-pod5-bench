#!/bin/bash

die()
{
	echo "$1" 1>&2
	exit 1
}

benchmark (){

	echo "BLOW5 C"
	for i in $(seq 1 5); do
		echo "Iteration $i"
		./run_rand.sh ${BLOW5} ${LIST} ${THREADS} 1000 c &> rand_slow5_${MACHINE}_${FILE}_${THREADS}_1000_c_${i}.log
	done

	echo "BLOW5 CXX"
	for i in $(seq 1 5); do
	echo "Iteration $i"
		./run_rand.sh ${BLOW5} ${LIST} ${THREADS} 1000 cxx &> rand_slow5_${MACHINE}_${FILE}_${THREADS}_1000_cxx_${i}.log
	done
}

THREADS=$(nproc)
MACHINE=gtgpu-ssd
FILE=PGXXXX230339

SOURCE_DIR=/data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5
SRC_BLOW5=/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5
SRC_LIST=/home/hasindu/scratch/hg2_prom_lsk114_5khz/500k.list
BLOW5=/data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5
LIST=/data/tmp/500k.list

cd ${SOURCE_DIR} || die "cd fail"
echo "Copying slow5 file"
test -e ${BLOW5} || cp ${SRC_BLOW5} ${BLOW5} || die "cp fail"
cp ${SRC_BLOW5}.idx ${BLOW5}.idx || die "cp fail"
cp ${SRC_LIST} ${LIST} || die "cp fail"

benchmark

echo "done"
#rm /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5.idx || die "rm fail"
rm ${LIST} || die "rm fail"

