#!/bin/bash

# steps
# run slow5_sequential
# run pod5_sequentail
# sort outputs
# diff outputs

set -x
RED='\033[0;31m' ; GREEN='\033[0;32m' ; NC='\033[0m' # No Color
die() { echo -e "${RED}$1${NC}" >&2 ; echo ; exit 1 ; } # terminate script
info() {  echo ; echo -e "${GREEN}$1${NC}" >&2 ; }
info "$(date)"

# read_id scale   offset  sampling_rate   len_raw_signal  signal_sums channel_number  read_number mux start_sample    run_id  experiment_id   flowcell_id position_id run_acquisition_start_time

BLOW5="/data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k_zstd-svb-zd.blow5"
POD5="/data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k.pod5 "

SLOW5_SEQUENTIAL="slow5/slow5_sequential"
POD5_SEQUENTIAL="pod5/pod5_sequential"
export LD_LIBRARY_PATH=$PWD/pod5_format/lib

${SLOW5_SEQUENTIAL} ${BLOW5} 16 4000 > slow5_out || die "slow5_sequential failed"
${POD5_SEQUENTIAL} ${POD5} 16 > pod5_out

cat pod5_out | cut -f 1-14 | sort -k1,1 > sorted_pod5
cat slow5_out | cut -f 1-14 | sort -k1,1 > sorted_slow5

diff sorted_pod5 sorted_slow5 || die "diff failed"
rm sorted_pod5 sorted_slow5 pod5_out slow5_out || die "rm failed"

info "success!"