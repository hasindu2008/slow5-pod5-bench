#!/bin/sh
# run experiments using one SLOW5 file

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
./setup.sh

if ! [ -e "$SLOW5".idx ]
then
	"$TOOLS_EXEC" index "$SLOW5" || die "Failed to index $SLOW5"
fi
./chkb5.sh "$SLOW5" || exit 1

t=$(../scripts/geomseqproc.sh)
b=1024
for i in $t
do
	./xpm.sh "$SLOW5" "$IDS" "$i" "$b" || die 'Threads experiment failed'
done

t=16
b='256 512 2048 4096 8192'
for i in $b
do
	./xpm.sh "$SLOW5" "$IDS" "$t" "$i" || die 'Batch experiment failed'
done

../scripts/diffrm.sh "$SLOW5".*"$RAND"*out || die "diff $RAND output failed"
../scripts/diffrm.sh "$SLOW5".*"$SEQ"*out || die "diff $SEQ output failed"
if [ -n "$RUN_CXX" ]
then
	../scripts/diffrm.sh "$SLOW5".*"$SEQ_CXX"*out \
		|| die "diff $SEQ_CXX output failed"
fi
