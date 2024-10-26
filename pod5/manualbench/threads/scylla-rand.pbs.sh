#!/bin/bash
###################################################################

# terminate script
die() {
	echo "$1" >&2
	echo
	exit 1
}

i=1
POD5=/data/hasindu/slow5-pod5-bench-data/PGXXXX230339_reads.pod5
LIST=/data/hasindu/slow5-pod5-bench-data/500k.list
MACHINE=scylla
FILE=PGXXXX230339

echo "POD5 IO"
for THREADS in 64 32 16 8 4 2 1; do
	echo "Iteration $i"
	./run_rand.sh ${POD5} ${LIST} ${THREADS} 1000 io &> rand_pod5_${MACHINE}_${FILE}_${THREADS}_io_${i}.log
done

echo "POD5 MMAP"
for THREADS in 64 32 16 8 4 2 1; do
	echo "Iteration $i"
	./run_rand.sh ${POD5} ${LIST} ${THREADS} 1000 mmap &> rand_pod5_${MACHINE}_${FILE}_${THREADS}_mmap_${i}.log
done

echo "done"