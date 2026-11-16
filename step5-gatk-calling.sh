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
## Call Variants (SNP)

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
##    -n 10 \                         ==> ??
##    -t 05-00:00:00 \                ==> ??
##    -J step5-gatk-calling-<SAMPLE NAME> \
##    step5-gatk-calling.sh <OUTPUT LOCATION> <INPUT BAM FILE> <REFERENCE GENOME>
=> Fill in the <> and check the ???

############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step5-gatk-calling.sh") 

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
module load gatk

############################################################################
##INPUT:

OUTPUTLOCATION=$(readlink -f $1)
INPUTFILE=$(readlink -f $2)
REFGENOME=$(readlink -f $3)

INPUTFILENAME=${INPUTFILE##*/}
SAMPLENAME=$(basename "$(dirname "$INPUTFILE")")

############################################################################
##OUTPUT:

OUTPUTFILEPREFIX=$(echo ${INPUTFILENAME} \
      | sed 's/\.bam.*$//' \
      | sed 's/-job[0-9].*$//' \
      | sed 's/\.BWAalign.mergebam.UMIdedup.*$//')
OUTPUTFILEPREFIX=$(echo "${OUTPUTLOCATION}/${SAMPLENAME}_${OUTPUTFILEPREFIX}.GATKcall-job${JOBID}")
OUTPUTFILE=$(echo "${OUTPUTFILEPREFIX}.g.vcf.gz")

############################################################################
##ACTIONS:


# Index reference genome
if [ ! -f ${REFGENOME}.fai ]; then
    samtools faidx $REFGENOME
fi

if [ ! -f ${REFGENOME%*.fasta}.dict ]; then
    gatk CreateSequenceDictionary -R $REFGENOME
fi

# Run GATK HapltypeCaller
gatk HaplotypeCaller \
    -R $REFGENOME \
    -I $INPUTFILE \
    -O $OUTPUTFILE \
    -ERC GVCF \
    --min-base-quality-score 25 \
    --minimum-mapping-quality 25


exit 0

