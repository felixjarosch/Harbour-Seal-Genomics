#!/bin/bash -l
##Add -l to the shebang to inherit bash profile variables and configuration.
##Required environment variables: ${PROJECT_ID}, ${MYSLURMFILE}, ${WORKDIR}.
############################################################################
################################## SCRIPT ##################################
############################################################################
##Author: Felix Jarosch (gusjarofe@student.gu.se).
############################################################################
##SCRIPT DESCRIPTION:

##Description:
##Decompresses and Indexes an reference genome with bwa for later alignment.

##Input $1: Output location.
##Input $2: FASTQ file (compressed reference genome) (.fastq.gz or .fq.gz).
##Output: Index files (.bwt, .pac, .ann, .amb, .sa)

##Usage:
##sbatch \
##    -A ${PROJECT_ID} \
##    -o ${MYSLURMFILE} \
##    -p shared \
##    -N 1 \
##    -n 4 \
##    -t 02-00:00:00 \
##    index_refgenome.sh

############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "index_refgenome.sh")

############################################################################
##JOB ID:

RUNDATE=$(date +"%Y%m%d%H%M%S")
if [[ -z "${SLURM_JOB_ID}" ]] ; then JOBID=${RUNDATE} ; else JOBID=${SLURM_JOB_ID} ; fi


############################################################################
##DIAGNOSTICS:

echo "$(date +"%Y-%m-%d @ %H:%M:%S"):
Submission: ${SCRIPTNAME} $@
User (\$USER): ${USER}
Host name (hostname -f): $(hostname -f)
Operating system: $(uname -a)
PATH: ${PATH}
Job ID (\$SLURM_JOB_ID): ${SLURM_JOB_ID}"

############################################################################
##LOAD TOOLS:

module load bioinfo-tools
module load bwa

############################################################################
##INPUT:

REFGENOME="$WORKDIR/original-files/referencegenomes/GSC_HSeal_1.0_HiC.fasta.gz"

############################################################################
##OUTPUT:

INDEXDIR="$WORKDIR/output/indexed_ref"
mkdir -p "$INDEXDIR"

############################################################################
##ACTIONS:

#Unzip reference genome  indexing
gunzip -c "$REFGENOME" > "$INDEXDIR/GSC_HSeal_1.0_HiC.fasta"

# Index the uncompressed reference genome
bwa index "$INDEXDIR/GSC_HSeal_1.0_HiC.fasta"

exit 0 



