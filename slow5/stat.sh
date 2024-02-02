#!/bin/sh
# print the current state
# usage: ./stat.sh

. ./cf.sh

date
grep -v ^# cf.sh
cc --version
c++ --version
gcc --version
g++ --version
printf '%s' 'slow5-pod5-bench '
git log | head -n 1
printf '%s' 'slow5lib '
git -C "$LIB" log | head -n 1
