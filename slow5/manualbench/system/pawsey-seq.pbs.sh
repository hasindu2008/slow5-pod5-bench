#!/bin/bash --login
#SBATCH --account=pawsey1099
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128
#SBATCH --exclusive
#SBATCH --time=00:24:00

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

THREADS=256

MACHINE=pawsey
FILE=PGXXXX230339
SOURCE_DIR=/home/hasindu/slow5-pod5-bench/slow5
BLOW5=/scratch/pawsey1099/hasindu/data/PGXXXX230339_reads_zstd-sv16-zd.blow5

# echo "BLOW5 C"
# for i in $(seq 1 5); do
# 	echo "Iteration $i"
# 	./run_seq.sh ${BLOW5}  ${THREADS} 1000 c &> seq_slow5_${MACHINE}_${FILE}_${THREADS}_1000_c_${i}.log
# done

echo "BLOW5 CXX"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_seq.sh ${BLOW5}  ${THREADS} 1000 cxx &> seq_slow5_${MACHINE}_${FILE}_${THREADS}_1000_cxx_${i}.log
done


echo "done"