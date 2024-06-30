#!/bin/bash
#PBS -P wv19
#PBS -N BLOW5
#PBS -q normal
#PBS -l ncpus=48
#PBS -l mem=192GB
#PBS -l walltime=48:00:00
#PBS -l wd
#PBS -l storage=gdata/if89+scratch/wv19+gdata/wv19+gdata/ox63

###################################################################

###################################################################

# Make sure to change:
# 1. wv19 and ox63 to your own projects

# to run:
# qsub ./gadi.pbs.sh

###################################################################

usage() {
	echo "Usage: qsub ./gadi.pbs.sh" >&2
	echo
	exit 1
}

###################################################################

# terminate script
die() {
	echo "$1" >&2
	echo
	exit 1
}

THREADS=${PBS_NCPUS}

echo "BLOW5 C"
for i in $(seq 1 5); do
	echo "Iteration $i"
	./run_seq.sh /g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads_zstd-sv16-zd.blow5  ${THREADS} 1000 c &> gadi_PGXXXX230339_reads_zstd-sv16-zd_${THREADS}_1000_c_${i}.log
done

echo "BLOW5 CXX"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_seq.sh /g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads_zstd-sv16-zd.blow5  ${THREADS} 1000 cxx &> gadi_PGXXXX230339_reads_zstd-sv16-zd_${THREADS}_1000_cxx_${i}.log
done

echo "done"