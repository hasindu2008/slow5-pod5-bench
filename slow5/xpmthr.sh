#!/bin/sh
# experiment using a range of threads and fixed batch size

USAGE="usage: $0 <slow5> <ids>"

. ./cf.sh

THREADS='1 2 4 8 16'
BATCH_SZ=1024

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 2 ]
then
	die "$USAGE"
fi

SLOW5=$1
IDS=$2

TMP=$SLOW5.tmp # temporary benchmarking output

RAND_OUT=$SLOW5."$RAND"_stdout
SEQ_OUT=$SLOW5."$SEQ"_stdout
SEQ_CXX_OUT=$SEQ_OUT # SEQ_CXX output does not differ from SEQ

clfs()
{
	clean_fscache || die 'Failed to clean the file system cache'
}

bench()
{
	/usr/bin/time -v $@
}

diffchk()
{
	if ! [ -e "$1" ]
	then
		cp "$2" "$1" || die "cp '$2' to '$1' failed"
	else
		diff -q "$1" "$2" || die "'$1' and '$2' differ"
	fi
}

if ! [ -e "$SLOW5".idx ]
then
	die "$SLOW5 is not indexed"
fi

# prep for diffchk
rm -f "$RAND_OUT" "$SEQ_OUT" "$SEQ_CXX_OUT"

for i in $THREADS
do
	# random
	stderr=$SLOW5.xpmthr"$i"_"$RAND"_stderr
	clfs
	bench "./$RAND" "$SLOW5" "$IDS" "$i" "$BATCH_SZ" \
		> "$TMP" 2> "$stderr" \
		|| die "$RAND failed for $i threads"
	diffchk "$RAND_OUT" "$TMP"

	# sequential
	stderr=$SLOW5.xpmthr"$i"_"$SEQ"_stderr
	clfs
	bench "./$SEQ" "$SLOW5" "$i" "$BATCH_SZ" \
		> "$TMP" 2> "$stderr" \
		|| die "$SEQ failed for $i threads"
	diffchk "$SEQ_OUT" "$TMP"

	if [ -n "$RUN_CXX" ]
	then
		# sequential cxxpool
		stderr=$SLOW5.xpmthr"$i"_"$SEQ_CXX"_stderr
		clfs
		bench "./$SEQ_CXX" "$SLOW5" "$i" "$BATCH_SZ" \
			> "$TMP" 2> "$stderr" \
			|| die "$SEQ_CXX failed for $i threads"
		diffchk "$SEQ_CXX_OUT" "$TMP"
	fi
done

rm -f "$TMP"
