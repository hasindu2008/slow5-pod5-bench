#!/bin/sh
# get power of 2 sequence from 1 to number of available processing units
# usage: ./geomseqproc.sh

$(dirname "$0")/geomseq.sh 1 $(nproc --all) 2
