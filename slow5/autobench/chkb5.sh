#!/bin/sh
# check slow5 has desired compression

USAGE="usage: $0 <slow5>"

. ./cf.sh

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 1 ]
then
	die "$USAGE"
fi

SLOW5=$1

test -e "$TOOLS_EXEC" || die "$TOOLS_EXEC does not exist"

# hacky: may break in the future
"$TOOLS_EXEC" stats "$SLOW5" 2> /dev/null | head -n8 \
	| grep -q "record compression method	$REC_PRESS
signal compression method	$SIG_PRESS" \
	|| die "$SLOW5 does not have $REC_PRESS record and $SIG_PRESS signal compression"
