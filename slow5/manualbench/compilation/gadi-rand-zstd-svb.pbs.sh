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

BLOW5=/g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads_zstd-svb-zd.blow5
LIST=/g/data/ox63/hasindu/slow5-pod5-bench/data/500k.list

test -e ${BLOW5} || die "ERROR: BLOW5 file not found: ${BLOW5}"
test -e ${BLOW5}.idx || die "ERROR: BLOW5 file index not found: ${BLOW5}.idx"
test -e ${LIST} || die "ERROR: LIST file not found: ${LIST}"

echo "BLOW5 CXX"
for THREADS in 92 48 32 16 8 4 2 1; do
	echo "Iteration $i"
	./run_rand.sh ${BLOW5} ${LIST} ${THREADS} 1000 cxx &> rand_slow5_${MACHINE}_${FILE}_zstd-svb-zd_${THREADS}_1000_cxx_${i}.log
done

echo "done"