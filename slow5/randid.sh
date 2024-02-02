#!/bin/sh
# print random permutation of all read ids from slow5 file

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

"$TOOLS_EXEC" skim --rid "$SLOW5" | sort -R \
	|| die 'Failed to print random read id list'
