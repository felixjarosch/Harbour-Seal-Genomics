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
##Align and index paired-end FastQ files to a reference genome using BWA, sort & index + get stats.

##Input $1: Output location.
##Input $2: FASTQ file (read 1, R1) (.fastq.gz or .fq.gz).
##Input $3: FASTQ file (read 2, R2) (.fastq.gz or .fq.gz).
##Input $4: Path to file prefix of BWA index of reference genome FASTA file.
##Output: BAM file (.bam) and index file.

##Usage:
##sbatch \
##    -A ${PROJECT_ID} \
##    -o ${MYSLURMFILE} \
##    -p shared \
##    -N 1 \
##    -n 30 \
##    -t 00-10:00:00 \
##    -J step2-bwa-alignment_<sample>-${DATE} \
##    step2-bwa-alignment.sh \
##    <Output location> \
##    <Input file1> \
##    <Input file2> \
##    <Indexed Ref-genome>

############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step2-bwa-alignment.sh")

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
module load samtools
module load bamtools
module load bcftools
module load bwa

############################################################################
##INPUT:

OUTPUTLOCATION=$(readlink -f $1)
INPUTFILE1=$(readlink -f $2)
INPUTFILE2=$(readlink -f $3)
REFGENOMEFILE=$(readlink -f $4)

############################################################################
##OUTPUT:

SAMPLENAME=${INPUTFILE1##*/}
SAMPLENAME=${SAMPLENAME%%_R1*}
OUTPUTFILEPREFIX=$(echo "${SAMPLENAME}.BWAalign-job${JOBID}")

OUTPUTFILE1=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bam")
OUTPUTFILE2=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsbamtools.txt")
OUTPUTFILE3=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatssamtools.txt")
OUTPUTFILE4=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsindex.txt")
OUTPUTFILE5=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsgenomecoverage.txt")
OUTPUTFILE6=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsgenomecoverageplots.txt")

TMPFILEPREFIX=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}")

############################################################################
##ACTIONS:

##Align reads and sort output BAM file.
bwa mem -M -t 10 ${REFGENOMEFILE} ${INPUTFILE1} ${INPUTFILE2} | \
	samtools view -S --bam --with-header - | \
	samtools sort -T ${TMPFILEPREFIX} -o ${OUTPUTFILE1} -

##Index BAM file.
samtools index --threads 10 -b ${OUTPUTFILE1}

##General statistics.
bamtools stats -in ${OUTPUTFILE1} > ${OUTPUTFILE2}
samtools stats ${OUTPUTFILE1} > ${OUTPUTFILE3}
samtools idxstats ${OUTPUTFILE1} > ${OUTPUTFILE4}
samtools coverage ${OUTPUTFILE1} >  ${OUTPUTFILE5}

##Genome-wide coverage histogram.
samtools coverage --ascii --plot-depth --n-bins 25 ${OUTPUTFILE1} > ${OUTPUTFILE6}
echo "
Average genome-wide coverage (samtools depth): " >> ${OUTPUTFILE6}
samtools depth -a ${OUTPUTFILE1} | awk '{sum+=$3; sumsq+=$3*$3} END {print "Average coverage = ",sum/NR; print "Std. Dev. = ",sqrt(sumsq/NR - (sum/NR)**2)}' >> ${OUTPUTFILE6}

exit 0

