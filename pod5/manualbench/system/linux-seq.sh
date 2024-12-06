#!/bin/sh

die()
{
	echo "$1" 1>&2
	exit 1
}

benchmark(){

	echo "POD5 IO"
	for i in $(seq 1 5); do
		echo "Iteration $i"
		./run_seq.sh ${POD5}  ${THREADS} io > seq_pod5_${MACHINE}_${FILE}_${THREADS}_io_${i}.log 2>&1
	done

	echo "POD5 MMAP"
	for i in $(seq 1 5); do
	echo "Iteration $i"
		./run_seq.sh ${POD5}  ${THREADS} mmap > seq_pod5_${MACHINE}_${FILE}_${THREADS}_mmap_${i}.log 2>&1
	done

}

test -z ${MACHINE} && die "MACHINE not set"
test -z ${FILE} && die "FILE not set"
test -z ${SOURCE_DIR} && die "SOURCE_DIR not set"
test -z ${POD5} && die "POD5 not set"

THREADS=$(nproc)
cd ${SOURCE_DIR} || die "cd fail"
test -e ${POD5} || die "${POD5} not found"
benchmark
echo "done"

