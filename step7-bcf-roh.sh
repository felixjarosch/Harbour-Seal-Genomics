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
##    -J step7-bcf-roh \
##    step7-bcf-roh.sh \
##    <OUTPUT LOCATION> \
##    <INPUT VCF> 


############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step7-bcf-roh.sh")

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
module load bcftools

############################################################################
##INPUT:

OUTPUTLOCATION=$(readlink -f $1)
INPUTFILE=$(readlink -f $2)

INPUTFILENAME=${INPUTFILE##*/}

############################################################################
##OUTPUT:

OUTPUTFILEPREFIX=$(echo ${INPUTFILENAME} \
      | sed 's/\.vcf.gz*$//' \
      | sed 's/-job[0-9].*$//' \
      | sed 's/BFCcall.BCFfiltered*$//' )
OUTPUTFILE=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.ROH-job${JOBID}.txt")

############################################################################
##ACTIONS:

bcftools roh \
    --AF-dflt 0.4 \
    --output "$OUTPUTFILE" \
    "$INPUTFILE"

exit 0
