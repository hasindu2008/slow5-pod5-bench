#!/bin/bash
#PBS -P ox63
#PBS -N POD5-DORADO
#PBS -q gpuvolta
#PBS -l ncpus=48
#PBS -l ngpus=4
#PBS -l mem=384GB
#PBS -l walltime=3:00:00
#PBS -l wd
#PBS -l storage=gdata/if89+scratch/ox63+gdata/ox63

###################################################################

#R10.4.1 5KHz
MODEL=/g/data/if89/apps/slow5-dorado/0.3.4/slow5-dorado/models/dna_r10.4.1_e8.2_400bps_fast@v4.2.0

###################################################################


###################################################################

usage() {
	echo "Usage: qsub ./slow5-dorado.pbs.sh" >&2
	echo
	exit 1
}

#module load /g/data/if89/apps/modulefiles/slow5-dorado/0.3.4
num_threads=${PBS_NCPUS}

# terminate script
die() {
	echo "$1" >&2
	echo
	exit 1
}

#MERGED_POD5=/g/data/ox63/hasindu/slow5-pod5-bench/data/PGXXXX230339_reads.pod5
MERGED_POD5=/g/data/ox63/hasindu/slow5-pod5-bench/data/
TMP_FASTQ=/scratch/ox63/hg1112/pod5.fastq

N_POD5=$(find ${MERGED_POD5} -name *.pod5 | wc -l)
if [ ${N_POD5} -ne 1 ]; then
	die "Only 1 pod5 file should be in ${MERGED_POD5}"
fi

clean_fscache || die "clean_fscache failed"

/usr/bin/time -v  /g/data/ox63/hasindu/dorados/dorado-0.3.4/bin/dorado basecaller ${MODEL} ${MERGED_POD5} --emit-fastq -x cuda:all  > ${TMP_FASTQ} 2> seq_pod5_gadi_PGXXXX230339_dorado034.log || die "basecalling failed"

echo "basecalling success"
