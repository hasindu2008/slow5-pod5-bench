#!/bin/sh
# run a benchmark experiment
# specify the number of threads

USAGE="usage: $0 <pod5> <list> <thr> <batch> <io/mmap>"


die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 5 ]
then
	die "$USAGE"
fi

POD5=$1
LIST=$2
T=$3
B=$4
C=$5
LAST_PROC=$(echo "$T-1" | bc)
RAND_CXX=pod5_rand

test -e "$POD5" || die "$POD5 does not exist"
test -e "$LIST" || die "$LIST does not exist"
test -d pod5_format || die "pod5_format not found"

export LD_LIBRARY_PATH=pod5_format/lib

if [ "$C" = "io" ]
then
	export POD5_DISABLE_MMAP_OPEN=1
elif [ "$C" = "mmap" ]
then
	echo "mmap"
else
	die "$USAGE"
fi

clean_fscache || die "clean_fscache failed"

test -x "$RAND_CXX" || die "$RAND_CXX does not exist"
/usr/bin/time -v taskset -a -c 0-"$LAST_PROC" "./$RAND_CXX" "$POD5" "$LIST" "$T" "$B"> /dev/null

