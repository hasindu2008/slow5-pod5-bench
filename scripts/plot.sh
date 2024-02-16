#!/bin/sh
# plot data in tsv(s)
# print result as png file
# example: ./plot tot_sec thr pig.tsv cow.tsv > pig_cow.timethr.png

USAGE="usage: $0 <y> <x> <tsv>..."

die()
{
	echo "$1" 1>&2
	exit 1
}

fmt()
{
	raw="$1"
	out=$(mktemp)
	tmp=$(mktemp)

	tail -n+2 "$raw" | xcol > "$tmp"
	tail -n+2 "$raw" | ycol | paste "$tmp" - > "$out"

	echo "$out"
}

if [ $# -lt 3 ]
then
	die "$USAGE"
fi

y=$1
x=$2

case $y in
disk_sec)
	title='Time to get all reads from memory'
	ylabel='disk time (sec)'
	ycol() { cut -f2; }
	;;
disk_upr)
	title='Time to get each read on average from memory'
	ylabel='disk time per read (usec/read)'
	ycol() { cut -f2,6 | awk '{ print $1/$2*1e6 }'; }
	;;
disk_rps)
	title='Number of reads retrieved from memory per second on average'
	ylabel='reads per second'
	ycol() { cut -f2,6 | awk '{ print $2/$1 }'; }
	;;
tot_sec)
	title='Time to get all reads'
	ylabel='total time (sec)'
	ycol() { cut -f3; }
	;;
tot_upr)
	title='Time to get each read on average'
	ylabel='total time per read (usec/read)'
	ycol() { cut -f3,6 | awk '{ print $1/$2*1e6 }'; }
	;;
tot_rps)
	title='Number of reads processed per second on average'
	ylabel='reads per second'
	ycol() { cut -f3,6 | awk '{ print $2/$1 }'; }
	;;
maxrss_gb)
	title='Peak RAM usage'
	ylabel='peak RAM (gigabytes)'
	ycol() { cut -f4; }
	;;
*) die "invalid y var: $y";;
esac

case "$x" in
thr)
	xlabel='number of threads'
	xcol() { cut -f1; }
	;;
maxbat)
	xlabel='size of the largest batch'
	xcol() { cut -f5; }
	;;
nread)
	xlabel='total number of reads'
	xcol() { cut -f6; }
	;;
*) die "invalid x var: $x";;
esac

dir=$(dirname "$0")

shift 2
for file in $@
do
	xy=$(fmt "$file")
	data="$data '$xy'"
	name="$name '$file'"
done

gnuplot -e "TITLE=\"$title\"" \
	-e "XLABEL=\"$xlabel\"" \
	-e "YLABEL=\"$ylabel\"" \
	-e "DATA=\"$data\"" \
	-e "NAME=\"$name\"" \
	"$dir/yx.gp"
