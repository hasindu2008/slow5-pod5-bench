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

i=1

MACHINE=gadi
FILE=PGXXXX230339

POD5=/g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads.pod5
LIST=/g/data/ox63/hasindu/slow5-pod5-bench/data/500k.list

test -e ${POD5} || die "ERROR: BLOW5 file not found: ${POD5}"
test -e ${LIST} || die "ERROR: LIST file not found: ${LIST}"

echo "POD5 MMAP"
for THREADS in 92 48 32 16 8 4 2 1; do
	echo "Iteration $i"
	./run_rand.sh ${POD5} ${LIST} ${THREADS} 1000 mmap &> rand_pod5_${MACHINE}_${FILE}_${THREADS}_mmap_${i}.log
done

echo "done"