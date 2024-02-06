#!/bin/sh
# run all experiments

USAGE="usage: $0 <slow5> <ids>"

. ./cf.sh

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

echo "$0 $*"
./stat.sh

./chklib.sh || exit 1
./build.sh || die 'build.sh failed'
if [ -n "$RUN_CXX" ]
then
	./build_cxxpool.sh || die 'build_cxxpool.sh failed'
fi

./install-tools.sh || exit 1
./chkb5.sh "$SLOW5" || exit 1

./xpmthr.sh "$SLOW5" "$IDS" || die 'Threads experiment failed'
./xpmbat.sh "$SLOW5" "$IDS" || die 'Batch experiment failed'
