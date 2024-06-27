#!/bin/sh
# get geometric sequence from start to end with ratio r

USAGE="usage: $0 <start> <end> <ratio>"

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 3 ]
then
	die "$USAGE"
fi

X=$1
Y=$2
R=$3

i=$X
while [ "$i" -lt "$Y" ]
do
	echo "$i"
	i=$(echo "$i * $R" | bc)
done
echo "$Y"
