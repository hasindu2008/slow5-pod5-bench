#!/bin/sh
# plot data in tsv: ram vs number of threads
# save result to png file

USAGE="usage: $0 <tsv>"

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 1 ]
then
	die "$USAGE"
fi

TSV=$1
DIR=$(dirname "$0")
DATA=$(mktemp)

tail -n+2 "$TSV" | cut -f1,4 > "$DATA"
gnuplot -e "data='$DATA'" "$DIR/ramthr.gp" > "$TSV.ramthr.png"
