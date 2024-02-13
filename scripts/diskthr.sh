#!/bin/sh
# plot data in tsv(s): disk time vs number of threads
# print result as png file

USAGE="usage: $0 <tsv>..."

TITLE='Time to get all reads from memory'
XLABEL='number of threads'
YLABEL='total disk time (sec)'

fmt()
{
	raw="$1"
	out=$(mktemp)

	tail -n+2 "$raw" | cut -f1,2 > "$out"

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
