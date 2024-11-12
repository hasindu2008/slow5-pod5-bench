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

benchmark (){

	# echo "BLOW5 C"
	# for i in $(seq 1 5); do
	# 	echo "Iteration $i"
	# 	./run_seq.sh ${BLOW5}  ${THREADS} 1000 c &> seq_slow5_${MACHINE}_${FILE}_${THREADS}_1000_c_${i}.log
	# done

	echo "BLOW5 CXX"
	for i in $(seq 1 5); do
	echo "Iteration $i"
		./run_seq.sh ${BLOW5} ${THREADS} 1000 cxx &> seq_slow5_${MACHINE}_${FILE}_${THREADS}_1000_cxx_${i}.log
	done

}

CPU=${PBS_NCPUS}
THREADS=$(echo "${CPU}*2" | bc)

MACHINE=gadi
FILE=PGXXSX240041
BLOW5=/g/data/ox63/hasindu/slow5-pod5-bench/datasets/hg2_prom_lsk114_5khz_2/${FILE}_reads_zstd-svb16-zd.blow5
test -e ${BLOW5} || die "ERROR: BLOW5 file not found: ${BLOW5}"

benchmark

echo "done"
