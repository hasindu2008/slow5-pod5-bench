#!/bin/bash
#PBS -P ox63
#PBS -N SLOW5-DORADO
#PBS -q gpuvolta
#PBS -l ncpus=48
#PBS -l ngpus=4
#PBS -l mem=384GB
#PBS -l walltime=48:00:00
#PBS -l wd
#PBS -l storage=gdata/if89+scratch/ox63+gdata/ox63

###################################################################

#R10.4.1 5KHz
MODEL=/g/data/if89/apps/slow5-dorado/0.3.4/slow5-dorado/models/dna_r10.4.1_e8.2_400bps_hac@v4.2.0

###################################################################


###################################################################

usage() {
	echo "Usage: qsub ./slow5-dorado.pbs.sh" >&2
	echo
	exit 1
}

module load /g/data/if89/apps/modulefiles/slow5-dorado/0.3.4
num_threads=${PBS_NCPUS}

# terminate script
die() {
	echo "$1" >&2
	echo
	exit 1
}

MERGED_SLOW5=/g/data/ox63/hasindu/hg2_prom_duplex/PGXHXX240196_reads.blow5
TMP_FASTQ=/scratch/ox63/hg1112/slow5_duplex.bam

clean_fscache || die "clean_fscache failed"

/usr/bin/time -v  slow5-dorado duplex ${MODEL} ${MERGED_SLOW5} --slow5_threads ${num_threads} --slow5_batchsize 1000  -x cuda:all  > ${TMP_FASTQ} 2> rand_slow5_gadi_PGXHXX240196_dorado034_48_1000_hac.log || die "basecalling failed"

echo "basecalling success"
