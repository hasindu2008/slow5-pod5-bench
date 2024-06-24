#!/bin/sh
# convert slow5 to blow5 with desired compression and index it

USAGE="usage: $0 <in_slow5> <out_blow5>"

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

IN=$1
OUT=$2

if ! [ -e "$TOOLS_EXEC" ]
then
	./install-tools.sh || die 'Failed to compile slow5tools'
fi

"$TOOLS_EXEC" view "$IN" -c "$REC_PRESS" -s "$SIG_PRESS" -o "$OUT" \
	|| die "Failed to create $OUT"
"$TOOLS_EXEC" index "$OUT" || die "Failed to index $OUT"
