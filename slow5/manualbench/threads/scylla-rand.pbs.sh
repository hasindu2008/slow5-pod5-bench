#!/bin/bash
###################################################################

# terminate script
die() {
	echo "$1" >&2
	echo
	exit 1
}

i=1

echo "BLOW5 CXX"
for THREADS in 32 16 8 4 2 1; do
	echo "Iteration $i"
	./run_rand.sh /data/hasindu/slow5-pod5-bench-data/PGXXXX230339_reads_zstd-sv16-zd.blow5  /data/hasindu/slow5-pod5-bench-data/500k.list ${THREADS} 1000 cxx &> rand_slow5_scylla_PGXXXX230339_${THREADS}_1000_cxx_${i}.log
done

echo "done"