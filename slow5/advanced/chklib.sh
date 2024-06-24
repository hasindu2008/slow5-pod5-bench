#!/bin/sh
# check lib is on the desired commit
# usage: ./chklib.sh

. ./cf.sh

die()
{
	echo "$1" 1>&2
	exit 1
}

commit=$(git -C "$LIB" log | head -n 1 | cut -d ' ' -f 2)
if [ -z "$commit" ]
then
	die "Failed to get current $LIB commit"
fi

if [ "$commit" != "$LIB_COMMIT" ]
then
	die "$LIB is not at commit $LIB_COMMIT"
fi
