#!/bin/sh
# run a benchmark experiment
# specify the number of threads and batch size

USAGE="usage: $0 <slow5> <thr> <batch> <c/cxx>"


die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 4 ]
then
	die "$USAGE"
fi

SLOW5=$1
T=$2
B=$3
C=$4
LAST_PROC=$(echo "$T-1" | bc)
SEQ=slow5_sequential
SEQ_CXX=slow5_sequential_cxxpool

test -e "$SLOW5" || die "$SLOW5 does not exist"

clean_fscache || die "clean_fscache failed"

if [ "$C" = "c" ]
then
	test -x "$SEQ" || die "$SEQ does not exist"
	/usr/bin/time -v taskset -a -c 0-"$LAST_PROC" "./$SEQ" ."$SLOW5" "$T" "$B"
elif [ "$C" = "cxx" ]
then
	test -x "$SEQ_CXX" || die "$SEQ_CXX does not exist"
	/usr/bin/time -v taskset -a -c 0-"$LAST_PROC" "./$SEQ_CXX" "$SLOW5" "$T" "$B"
else
	die "$USAGE"
fi

