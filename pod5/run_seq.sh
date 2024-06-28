#!/bin/sh
# run a benchmark experiment
# specify the number of threads

USAGE="usage: $0 <pod5> <thr> <io/mmap>"


die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 3 ]
then
	die "$USAGE"
fi

POD5=$1
T=$2
LAST_PROC=$(echo "$T-1" | bc)
SEQ_CXX=pod5_sequential

test -e "$POD5" || die "$POD5 does not exist"
test -d pod5_format || die "pod5_format not found"

export LD_LIBRARY_PATH=pod5_format/lib

if [ "$3" = "io" ]
then
	export POD5_DISABLE_MMAP_OPEN=1
elif [ "$3" = "mmap" ]
then
else
	die "$USAGE"
fi

clean_fscache || die "clean_fscache failed"

test -x "$SEQ_CXX" || die "$SEQ_CXX does not exist"
/usr/bin/time -v taskset -a -c 0-"$LAST_PROC" "./$SEQ_CXX" "$POD5" "$T" > /dev/null

