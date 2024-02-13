#!/bin/sh
# plot data in two tsvs: disk time vs number of threads
# print result as png file

USAGE="usage: $0 <tsv1> <tsv2>"

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 2 ]
then
	die "$USAGE"
fi

TSV1=$1
TSV2=$2
DIR=$(dirname "$0")
DATA1=$(mktemp)
DATA2=$(mktemp)

tail -n+2 "$TSV1" | cut -f1,2 > "$DATA1"
tail -n+2 "$TSV2" | cut -f1,2 > "$DATA2"

gnuplot -e "tsv1='$TSV1'" \
	-e "tsv2='$TSV2'" \
	-e "data1='$DATA1'" \
	-e "data2='$DATA2'" \
	"$DIR/diskthr2.gp"
