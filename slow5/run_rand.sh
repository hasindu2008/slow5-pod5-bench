#!/bin/sh
# run a benchmark experiment
# specify the number of threads and batch size

USAGE="usage: $0 <slow5> <list> <thr> <batch> <c/cxx>"


die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 5 ]
then
	die "$USAGE"
fi

SLOW5=$1
LIST=$2
T=$3
B=$4
C=$5
LAST_PROC=$(echo "$T-1" | bc)
RAND=slow5_random
RAND_CXX=slow5_random_cxxpool

test -e "$SLOW5" || die "$SLOW5 does not exist"
test -e "$SLOW5".idx || die "$SLOW5.idx does not exist"
test -e "$LIST" || die "$LIST does not exist"

clean_fscache || die "clean_fscache failed"

if [ "$C" = "c" ]
then
	test -x "$RAND" || die "$RAND does not exist"
	/usr/bin/time -v taskset -a -c 0-"$LAST_PROC" "./$RAND" "$SLOW5" "$LIST" "$T" "$B" > /dev/null
elif [ "$C" = "cxx" ]
then
	test -x "$RAND_CXX" || die "$RAND_CXX does not exist"
	/usr/bin/time -v taskset -a -c 0-"$LAST_PROC" "./$RAND_CXX" "$SLOW5" "$LIST" "$T" "$B" > /dev/null
else
	die "$USAGE"
fi

