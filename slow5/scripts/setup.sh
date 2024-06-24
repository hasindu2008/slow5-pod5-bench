#!/bin/sh
# setup the environment for benchmarking
# usage: ./setup.sh

. ./cf.sh

die()
{
	echo "$1" 1>&2
	exit 1
}

./chklib.sh || exit 1
./build.sh || die 'build.sh failed'
if [ -n "$RUN_CXX" ]
then
	./build_cxxpool.sh || die 'build_cxxpool.sh failed'
fi

./install-tools.sh || exit 1
