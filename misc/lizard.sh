#!/bin/sh
# Print lizard statistics given paths
# Usage: ./lizard.sh [<path> ...]
# E.g. ./lizard.sh Makefile include/slow5/slow5* include/slow5/klib/* src/slow5* src/klib/* thirdparty/streamvbyte/Makefile  thirdparty/streamvbyte/include/*  thirdparty/streamvbyte/src/*

USAGE="$0 [<path> ...]"

if [ "$#" -eq 0 ]
then
	echo "$USAGE" 2>&1
	exit 1
fi

die() {
	echo "$@" 1>&2
	exit 1
}

lizard --version || die "lizard not found, please install lizard"
datamash --version || die "datamash not found, please install datamash"

wc -l "$@"

lizard "$@" > lizard.out
sed 's/^ \+//' -i lizard.out # remove leading spaces
sed 's/ \+/	/g' -i lizard.out # spaces to tabs

sed '1,/^=/d' lizard.out | sed '/^=/,$d' | head -n-1 > lizard.out.file
sed '0,/^=/d' lizard.out | sed '/^=/,$d' | head -n-1 > lizard.out.func

loc=$(tail -n+3 lizard.out.file | sort -u | datamash sum 1)
loc_avg=$(tail -n+3 lizard.out.file | sort -u | datamash mean 2)
ccn_avg=$(tail -n+3 lizard.out.file | sort -u | datamash mean 3)
tok_avg=$(tail -n+3 lizard.out.file | sort -u | datamash mean 4)
func=$(tail -n+3 lizard.out.file | sort -u | datamash sum 5)

#floc=$(tail -n+3 lizard.out.func | sort -u | datamash sum 1)
ccn=$(tail -n+3 lizard.out.func | sort -u | datamash sum 2)
tok=$(tail -n+3 lizard.out.func | sort -u | datamash sum 3)
param=$(tail -n+3 lizard.out.func | sort -u | datamash sum 4)
#len=$(tail -n+3 lizard.out.func | sort -u | datamash sum 5)

echo 'LOC	CCN	Tokens	Params	Fns'
echo "$loc	$ccn	$tok	$param	$func"
echo 'Avg.LOC/Fn	Avg.CCN/Fn	Avg.Tokens/Fn'
echo "$loc_avg	$ccn_avg	$tok_avg"
