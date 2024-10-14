#!/bin/bash
#PBS -P ox63
#PBS -N EEL
#PBS -q gpuvolta
#PBS -l ncpus=48
#PBS -l ngpus=4
#PBS -l mem=384GB
#PBS -l walltime=5:00:00
#PBS -l wd
#PBS -l storage=gdata/if89+scratch/ox63+gdata/ox63

###################################################################

# Change this to the model you want to use
MODEL=dna_r10.4.1_e8.2_400bps_5khz_fast_prom.cfg
# MODEL=dna_r10.4.1_e8.2_400bps_sup.cfg
# MODEL=dna_r10.4.1_e8.2_400bps_hac_prom.cfg
# MODEL=dna_r9.4.1_450bps_sup.cfg
# MODEL=dna_r9.4.1_450bps_hac_prom.cfg

###################################################################

###################################################################

usage() {
	echo "Usage: qsub ./buttery-eel.pbs.sh" >&2
	echo
	exit 1
}

module load /g/data/if89/apps/modulefiles/buttery-eel/0.4.3+dorado7.2.13

###################################################################

# terminate script
die() {
	echo "$1" >&2
	echo
	exit 1
}

#https://unix.stackexchange.com/questions/55913/whats-the-easiest-way-to-find-an-unused-local-port
PORT=5000
get_free_port() {
	for port in $(seq 5000 65000); do
		echo "trying port $port" >&2
		PORT=$port
		ss -lpna | grep -q ":$port " || break
	done
}

get_free_port
test -z "${PORT}" && die "Could not find a free port"
echo "Using port ${PORT}"

ONT_DORADO_PATH=$(which dorado_basecall_server | sed "s/dorado\_basecall\_server$//")/
${ONT_DORADO_PATH}/dorado_basecall_server --version || die "Could not find dorado_basecall_server"

MERGED_SLOW5=/g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads_zstd-svb-zd.blow5

test -e ${MERGED_SLOW5} || die "${MERGED_SLOW5} not found. Exiting."

BASECALL_OUT=/scratch/ox63/hg1112/slow5-eel/
mkdir -p ${BASECALL_OUT}
cd ${BASECALL_OUT} || die "${MERGED_SLOW5} not found. Exiting."

/usr/bin/time -v  buttery-eel -i ${MERGED_SLOW5} -o ${BASECALL_OUT}/reads.fastq --guppy_bin ${ONT_DORADO_PATH} --port ${PORT} --use_tcp --config ${MODEL} -x cuda:all  --slow5_threads 10 --slow5_batchsize 1000 --procs 20 2> seq_slow5_gadi_PGXXXX230339_eel043-7213_48_1000.log || die "basecalling failed"

echo "basecalling success"
