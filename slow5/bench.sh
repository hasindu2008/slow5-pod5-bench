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

thr=$(../scripts/geomseqproc.sh)
bat=1024
for i in $thr
do
	./xpm.sh "$SLOW5" "$IDS" "$i" "$bat" || die 'Threads experiment failed'
done

thr=16
bat='1 32 1024 32768 1048576'
for i in $bat
do
	./xpm.sh "$SLOW5" "$IDS" "$thr" "$i" || die 'Batch experiment failed'
done

../scripts/diffrm.sh "$SLOW5".*"$RAND"*out || die "diff $RAND output failed"
../scripts/diffrm.sh "$SLOW5".*"$SEQ"*out || die "diff $SEQ output failed"
if [ -n "$RUN_CXX" ]
then
	../scripts/diffrm.sh "$SLOW5".*"$SEQ_CXX"*out \
		|| die "diff $SEQ_CXX output failed"
fi
