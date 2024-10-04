#!/bin/bash

die()
{
	echo "$1" 1>&2
	exit 1
}

benchmark(){

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

}

test -z ${MACHINE} && die "MACHINE not set"
test -z ${FILE} && die "FILE not set"
test -z ${SOURCE_DIR} && die "SOURCE_DIR not set"
test -z ${BLOW5} && die "BLOW5 not set"

THREADS=$(nproc)
cd ${SOURCE_DIR} || die "cd fail"
test -e ${BLOW5} || die "${BLOW5} not found"
benchmark
echo "done"

