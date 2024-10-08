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

CPU=${PBS_NCPUS}
i=1

echo "BLOW5 CXX"
for THREADS in 92 48 32 16 8 4 2 1; do
	echo "Iteration $i"
	./run_seq.sh /g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads_zstd-sv16-zd.blow5  ${THREADS} 1000 cxx &> seq_slow5_gadi_PGXXXX230339_${THREADS}_1000_cxx_${i}.log
done

echo "done"