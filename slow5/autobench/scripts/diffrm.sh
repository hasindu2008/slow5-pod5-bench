#!/bin/sh
# diff files and if they are the same remove all except the first file

USAGE="usage: $0 FILES..."

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -lt 2 ]
then
	die "$USAGE"
fi

from=$1
shift
diff -q --from-file "$from" $@ || exit 1
rm $@
