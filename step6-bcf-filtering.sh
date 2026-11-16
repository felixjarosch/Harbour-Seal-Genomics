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
##Filter VCF to only contain high-quality SNPs.

##Input $1: Output location.
##Input $2: raw VCF file.
##Output: Filtered VCF file and VCF index file (.tbi).

##Usage:
##sbatch \
##    -A ${PROJECT_ID} \
##    -o ${MYSLURMFILE} \
##    -p shared \
##    -N 1 \
##    -n 10 \                         ==> ??
##    -t 05-00:00:00 \                ==> ??
##    -J step6-bcf-filtering-<SAMPLE NAME> \
##    step6-bcf-filtering.sh <OUTPUT LOCATION> <INPUT VCF FILE>
=> Fill in the <> and check the ???

############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step6-bcf-filtering.sh")

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
      | sed 's/\.g.vcf.gz.*$//' \
      | sed 's/-job[0-9].*$//')
OUTPUTFILEPREFIX=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.BCFfiltered-job${JOBID}")
OUTPUTFILE=$(echo "${OUTPUTFILEPREFIX}.vcf.gz")

############################################################################
##ACTIONS:

#SNP filtering
bcftools view --min-alleles 2 --max-alleles 2 --types snps -i 'QUAL>30 && INFO/DP>8 && INFO/DP<2*AVG_DP && FORMAT/AD[GT] > 2 && MQ>40' --write-index=tbi --output-type z --output ${OUTPUTFILE} ${INPUTFILE}

# Index output VCF
bcftools index "$OUTPUTFILE"

exit 0

