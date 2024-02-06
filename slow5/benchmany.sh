#!/bin/sh
# run experiments using many SLOW5 file
# example: ./benchmany.sh pig.slow5 pig.ids cow.slow5 cow.ids

USAGE="usage: $0 <slow5> <ids>..."

. ./cf.sh

die()
{
	echo "$1" 1>&2
	exit 1
}

even=$(echo "$# % 2" | bc)
if [ $# -eq 0 ] || [ "$even" -ne 0 ]
then
	die "$USAGE"
fi

echo "$0 $*"
./stat.sh
./setup.sh

t=16
b=1024
while [ $# -ne 0 ]
do
	slow5=$1
	ids=$2

	if ! [ -e "$slow5".idx ]
	then
		"$TOOLS_EXEC" index "$slow5" || die "Failed to index $slow5"
	fi
	./chkb5.sh "$slow5" || exit 1
	./xpm.sh "$slow5" "$ids" "$t" "$b" || die 'Experiment failed'

	shift 2
done
