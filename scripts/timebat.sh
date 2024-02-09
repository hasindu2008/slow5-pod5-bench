#!/bin/sh
# plot data in tsv: time vs size of the largest batch
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

tail -n+2 "$TSV" | awk '{print ($5,"\t",$3)}' > "$DATA"
gnuplot -e "data='$DATA'" "$DIR/timebat.gp" > "$TSV.timebat.png"
