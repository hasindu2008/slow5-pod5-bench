#!/bin/bash

# steps
# run slow5_random
# run pod5_random
# sort outputs
# diff outputs

set -x
RED='\033[0;31m' ; GREEN='\033[0;32m' ; NC='\033[0m' # No Color
die() { echo -e "${RED}$1${NC}" >&2 ; echo ; exit 1 ; } # terminate script
info() {  echo ; echo -e "${GREEN}$1${NC}" >&2 ; }
info "$(date)"

if [ "$1" = 'mem' ]; then
    mem=1
else
    mem=0
fi

ex() {
    if [ $mem -eq 1 ]; then
        valgrind --suppressions=test/valgrind.supp --leak-check=full --error-exitcode=1 "$@"
    else
        "$@"
    fi
}

# read_id scale   offset  sampling_rate   len_raw_signal  signal_sums channel_number  read_number mux start_sample    run_id  experiment_id   flowcell_id position_id run_acquisition_start_time

BLOW5="/data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k_zstd-svb-zd.blow5"
POD5="/data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k.pod5 "

SLOW5_RANDOM="slow5/slow5_random"
SLOW5_RANDOM_CXX="slow5/slow5_random_cxxpool"
POD5_RANDOM="pod5/pod5_random"
export LD_LIBRARY_PATH=$PWD/pod5/pod5_format/lib

test -f ${BLOW5} || die "blow5 file not found"
test -f ${POD5} || die "pod5 file not found"
test -x ${SLOW5_RANDOM} || die "slow5_random not found"
test -x ${SLOW5_RANDOM_CXX} || die "slow5_random_cxxpool not found"
test -x ${POD5_RANDOM} || die "pod5_random not found"
slow5tools --version || die "slow5tools not found"

# random list
slow5tools skim --rid /data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k.blow5 | sort -R > random_list.txt || die "skim failed"

ex ${SLOW5_RANDOM} ${BLOW5} random_list.txt 16 1000 > slow5_out || die "slow5_random failed"
ex ${SLOW5_RANDOM_CXX} ${BLOW5} random_list.txt 16 1000 > slow5_out2 || die "slow5_random failed"
ex ${POD5_RANDOM} ${POD5} random_list.txt 16 1000 > pod5_out || die "pod5_random failed"

cat pod5_out | cut -f 1-14 | sort -k1,1 > sorted_pod5 || die "sort failed"
cat slow5_out | cut -f 1-14 | sort -k1,1 > sorted_slow5 || die "sort failed"
cat slow5_out2 | cut -f 1-14 | sort -k1,1 > sorted_slow52 || die "sort failed"

diff sorted_pod5 sorted_slow5 || die "diff failed"
diff sorted_pod5 sorted_slow52 || die "diff failed"
rm sorted_pod5 sorted_slow5 sorted_slow52 pod5_out slow5_out slow5_out2 random_list.txt || die "rm failed"

info "success!"