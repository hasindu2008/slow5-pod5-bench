#!/bin/sh
# plot data in tsv(s): time vs size of the largest batch
# print result as png file

USAGE="usage: $0 <tsv>..."

TITLE='Time to get all reads'
XLABEL='size of the largest batch'
YLABEL='total time (sec)'

fmt()
{
	raw="$1"
	out=$(mktemp)
	tmp=$(mktemp)

	tail -n+2 "$raw" | cut -f5 > "$tmp"
	tail -n+2 "$raw" | cut -f3 | paste "$tmp" - > "$out"

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
