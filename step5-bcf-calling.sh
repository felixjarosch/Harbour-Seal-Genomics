#!/bin/bash -l
##Add -l to the shebang to inherit bash profile variables and configuration.
##Required environment variables: ${PROJECT_ID}, ${MYSLURMFILE}.
############################################################################
################################## SCRIPT ##################################
############################################################################
##Author: Felix Jarosch (gusjarofe@student.gu.se).
############################################################################
##SCRIPT DESCRIPTION:

##Description:
## Call Variants in sample genomes compared to the reference genome.

##Input $1: Output location.
##Input $2: BAM file (dedup.bam).
##Input $3: Reference Genome.
##Output: Sample VCF file and VCF index file (.tbi).

##Usage:
##sbatch \
##    -A ${PROJECT_ID} \
##    -o ${MYSLURMFILE} \
##    -p shared \
##    -N 1 \
##    -n 10 \
##    -t 01-00:00:00 \
##    -J step5-bcf-calling \
##    step5-bcf-calling.sh \
##    <OUTPUT LOCATION> \
##    <INPUT BAM LIST> \
##    <REFERENCE GENOME>


############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step5-bcf-calling.sh") 

############################################################################
##JOB ID:

RUNDATE=$(date +"%Y%m%d%H%M%S")
if [[ -z "${SLURM_JOB_ID}" ]] ; then JOBID=${RUNDATE} ; else JOBID=${SLURM_JOB_ID} ; fi 

###########################################################################
##DIAGNOSTICS:

echo "$(date +"%Y-%m-%d @ %H:%M:%S"): 
Submission: ${SCRIPTNAME} $@
User (\$USER): ${USER}
Host name (hostname -f): $(hostname -f)
Job ID (\$SLURM_JOB_ID): ${SLURM_JOB_ID}"

############################################################################
##LOAD TOOLS:

module load bioinfo-tools
module load samtools
module load bcftools

############################################################################
##INPUT:

OUTPUTLOCATION=$(readlink -f $1)
INPUTFILE=$(readlink -f $2)
REFGENOME=$(readlink -f $3)

############################################################################
##OUTPUT:

OUTPUTFILE=$(echo "Pv-ANH_Pv-KAL_BCFcall-job${JOBID}.vcf.gz")

############################################################################
##ACTIONS:


# Index reference genome
if [ ! -f ${REFGENOME}.fai ]; then
    samtools faidx $REFGENOME
fi


# Run Call Variants in BCFtools
bcftools mpileup \
    -f $REFGENOME \
    -Ou \
    -q 25 \
    -Q 25 \
    -d 10000 \
    -b $INPUTFILE | \
bcftools call \
    -mv \
    -Oz \
    -o "$OUTPUTFILE"

# Index output VCF
bcftools index "$OUTPUTFILE"


exit 0

