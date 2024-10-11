#!/bin/bash --login
#SBATCH --account=pawsey1099
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128
#SBATCH --exclusive
#SBATCH --time=24:00:00

###################################################################

###################################################################

# to run:
# sbatch ./pawsey.sh

###################################################################

usage() {
	echo "Usage: sbatch ./pawsey.sh" >&2
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
	# 	./run_rand.sh ${BLOW5} ${LIST} ${THREADS} 1000 c &> rand_slow5_${MACHINE}_${FILE}_${THREADS}_1000_c_${i}.log
	# done

	echo "BLOW5 CXX"
	for i in $(seq 1 5); do
	echo "Iteration $i"
		./run_rand.sh ${BLOW5} ${LIST} ${THREADS} 1000 cxx &> rand_slow5_${MACHINE}_${FILE}_${THREADS}_1000_cxx_${i}.log
	done
}

THREADS=256
MACHINE=pawsey
FILE=PGXXXX230339
SOURCE_DIR=/home/hasindu/slow5-pod5-bench/slow5
BLOW5=/scratch/pawsey1099/hasindu/data/PGXXXX230339_reads_zstd-sv16-zd.blow5
LIST=/scratch/pawsey1099/hasindu/data/500k.list

test -e ${BLOW5} || die "ERROR: BLOW5 file not found: ${BLOW5}"
test -e ${BLOW5}.idx || die "ERROR: BLOW5 file index not found: ${BLOW5}.idx"
test -e ${LIST} || die "ERROR: LIST file not found: ${LIST}"

benchmark

echo "done"