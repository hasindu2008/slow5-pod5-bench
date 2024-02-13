#!/bin/sh
# plot data in tsv(s): ram vs number of threads
# print result as png file

USAGE="usage: $0 <tsv>..."

TITLE='Peak RAM usage'
XLABEL='number of threads'
YLABEL='peak RAM (gigabytes)'

fmt()
{
	raw="$1"
	out=$(mktemp)

	tail -n+2 "$raw" | cut -f1,4 > "$out"

	echo "$out"
}

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -eq 0 ]
then
	die "$USAGE"
fi

dir=$(dirname "$0")

for file in $@
do
	xy=$(fmt "$file")
	data="$data '$xy'"
	name="$name '$file'"
done

gnuplot -e "TITLE=\"$TITLE\"" \
	-e "XLABEL=\"$XLABEL\"" \
	-e "YLABEL=\"$YLABEL\"" \
	-e "DATA=\"$data\"" \
	-e "NAME=\"$name\"" \
	"$dir/yx.gp"
