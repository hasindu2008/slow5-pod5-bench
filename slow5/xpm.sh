#!/bin/sh
# run a benchmark experiment
# specify the number of threads and batch size

USAGE="usage: $0 <slow5> <ids> <thr> <batch>"

. ./cf.sh

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
IDS=$2
T=$3
B=$4

TOMB="failed with $T threads and batch size $B"
LAST_PROC=$(echo "$T-1" | bc)
OUT_PREFIX=$SLOW5.t"$T"_b"$B"

clfs()
{
	clean_fscache || die 'Failed to clean the file system cache'
}

bench()
{
	pgr=$1
	shift

	pre="$OUT_PREFIX"_"$pgr"
	out="$pre"_out
	err="$pre"_err

	clfs
	/usr/bin/time -v taskset -a -c 0-"$LAST_PROC" $@ \
		> "$out" 2> "$err" || die "$pgr $TOMB"
}

if ! [ -e "$SLOW5".idx ]
then
	die "$SLOW5 is not indexed"
fi

bench "$RAND" "./$RAND" "$SLOW5" "$IDS" "$T" "$B"
bench "$SEQ" "./$SEQ" "$SLOW5" "$T" "$B"
if [ -n "$RUN_CXX" ]
then
	bench "$SEQ_CXX" "./$SEQ_CXX" "$SLOW5" "$T" "$B"
fi
