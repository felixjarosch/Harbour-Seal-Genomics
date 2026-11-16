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
##Pre-process (QC and adapter trimming) paired-end FastQ files using Fastp.

##Input $1: Output location.
##Input $2: FASTQ file (read 1, R1) (.fastq.gz or .fq.gz).
##Input $3: FASTQ file (read 2, R2) (.fastq.gz or .fq.gz).
##Output: FASTQ files (.fastq.gz) and report files (.json and .html).

##Usage: 
##sbatch \
##    -A ${PROJECT_ID} \
##    -o ${MYSLURMFILE} \
##    -p shared \
##    -N 1 \
##    -n 50 \
##    -t 00-10:00:00 \
##    -J step1-fastp-preprocessing \
##    step1-fastp-preprocessing.sh <OUTPUTLOCATION> <INPUTFILE1> <INPUTFILE2>

############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step1-fastp-preprocessing.sh") 

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
Job ID (\$SLURM_JOB_ID): ${SLURM_JOB_ID}"

############################################################################
##LOAD TOOLS:

module load bioinfo-tools
module load fastp/0.23.4
module load pigz
module load seqtk

############################################################################
##INPUT:

OUTPUTLOCATION=$(readlink -f $1)
INPUTFILE1=$(readlink -f $2)
INPUTFILE2=$(readlink -f $3)

INPUTFILE1NAME=${INPUTFILE1##*/}
INPUTFILE2NAME=${INPUTFILE2##*/}

############################################################################
##OUTPUT:

#set a consensus name per individual
SAMPLENAME="${INPUTFILE1NAME%_1*}"

#Name Output-files
OUTPUTFILE1="${OUTPUTLOCATION}/${SAMPLENAME}_R1.fastp.fastq.gz"
OUTPUTFILE2="${OUTPUTLOCATION}/${SAMPLENAME}_R2.fastp.fastq.gz"
OUTPUTFILE3="${OUTPUTLOCATION}/${SAMPLENAME}.fastp_report.json"
OUTPUTFILE4="${OUTPUTLOCATION}/${SAMPLENAME}.fastp_report.html"

############################################################################
##ACTIONS:

fastp \
	--in1 ${INPUTFILE1} \
	--in2 ${INPUTFILE2} \
	--out1 ${OUTPUTFILE1} \
        --out2 ${OUTPUTFILE2} \
	--json ${OUTPUTFILE3} \
	--html ${OUTPUTFILE4} \
	--dont_overwrite \
	--trim_poly_x \
	--trim_poly_g \
	--umi \
        --umi_loc read1 \
        --umi_len 12 \
	--overrepresentation_analysis \
	--overrepresentation_sampling 100 \
	--detect_adapter_for_pe \
	--qualified_quality_phred 20 \
	--thread 10

#Edit Headers to be compatible with bwa
zcat ${OUTPUTFILE1} | sed '1~4s/\// /' | gzip > ${OUTPUTFILE1}.tmp
zcat ${OUTPUTFILE2} | sed '1~4s/\// /' | gzip > ${OUTPUTFILE2}.tmp

mv ${OUTPUTFILE1}.tmp ${OUTPUTFILE1}
mv ${OUTPUTFILE2}.tmp ${OUTPUTFILE2}

exit 0

