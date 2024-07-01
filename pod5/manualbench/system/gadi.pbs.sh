#!/bin/bash
#PBS -P ox63
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

echo "POD5 IO"
for i in $(seq 1 5); do
	echo "Iteration $i"
	./run_seq.sh /g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads.pod5  ${THREADS} io &> gadi_PGXXXX230339_reads_${THREADS}_io_${i}.log
done

echo "POD5 MMAP"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_seq.sh /g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads.pod5 ${THREADS} mmap &> gadi_PGXXXX230339_reads_${THREADS}_mmap_${i}.log
done

echo "done"