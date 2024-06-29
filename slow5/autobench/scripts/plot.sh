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
	title='Time to get each read from memory on average'
	ylabel='disk time per read (usec/read)'
	ycol() { cut -f2,6 | awk '{ print $1/$2*1e6 }'; }
	;;
disk_rps)
	title='Number of reads retrieved from memory per second on average'
	ylabel='reads per second'
	ycol() { cut -f2,6 | awk '{ print $2/$1 }'; }
	;;
disk_spg)
	title='Time to get each gigabyte from memory on average'
	ylabel='disk time per gigabyte (sec/GB)'
	ycol() { cut -f2,7 | awk '{ print $1/$2*1e9 }'; }
	;;
disk_gps)
	title='Number of gigabytes retrieved from memory per second on average'
	ylabel='gigabytes per second'
	ycol() { cut -f2,7 | awk '{ print $2/$1/1e9 }'; }
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
tot_spg)
	title='Time to get each gigabyte on average'
	ylabel='total time per gigabyte (sec/GB)'
	ycol() { cut -f3,7 | awk '{ print $1/$2*1e9 }'; }
	;;
tot_gps)
	title='Number of gigabytes processed per second on average'
	ylabel='gigabytes per second'
	ycol() { cut -f3,7 | awk '{ print $2/$1/1e9 }'; }
	;;
maxrss_gb)
	title='Peak RAM usage'
	ylabel='peak RAM (GiB)'
	ycol() { cut -f4; }
	;;
diskminflt)
	title='Number of soft page faults (without I/O) while retrieving reads'
	ylabel='soft page faults'
	ycol() { cut -f8; }
	;;
diskmajflt)
	title='Number of hard page faults (with I/O) while retrieving reads'
	ylabel='hard page faults'
	ycol() { cut -f9; }
	;;
totminflt)
	title='Number of soft page faults (without I/O)'
	ylabel='soft page faults'
	ycol() { cut -f10; }
	;;
totmajflt)
	title='Number of hard page faults (with I/O)'
	ylabel='hard page faults'
	ycol() { cut -f11; }
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
bytes)
	xlabel='file size (bytes)'
	xcol() { cut -f7; }
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
