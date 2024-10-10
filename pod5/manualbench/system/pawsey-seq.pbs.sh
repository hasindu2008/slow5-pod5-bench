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

THREADS=256

MACHINE=pawsey
FILE=PGXXXX230339
SOURCE_DIR=/home/hasindu/slow5-pod5-bench/pod5
POD5=/scratch/pawsey1099/hasindu/data/PGXXXX230339_reads.pod5


echo "POD5 IO"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_seq.sh ${POD5} ${THREADS} io &> seq_pod5_${MACHINE}_${FILE}_${THREADS}_io_${i}.log
done

echo "POD5 MMAP"
for i in $(seq 1 5); do
echo "Iteration $i"
	./run_seq.sh ${POD5} ${THREADS} mmap &> seq_pod5_${MACHINE}_${FILE}_${THREADS}_mmap_${i}.log
done

echo "done"