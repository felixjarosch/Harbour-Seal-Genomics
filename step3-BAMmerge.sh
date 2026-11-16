#!/bin/bash -l
##Add -l to the shebang to inherit bash profile variables and configuration.
##Required environment variables: ${PATHTOMYSUBMITTEDSCRIPTS}, ${PATHTOMYSLURM}, ${PATHTOPROJTMP}, ${PROJECT_ID}, ${MYSLURMFILE}, ${MYEMAIL}.
############################################################################
################################## SCRIPT ##################################
############################################################################
##Author: Felix Jarosch (gusjarofe@student.gu.se).
############################################################################
##SCRIPT DESCRIPTION:

##Description:
##Merge BAM files (.bam). => Different Lanes per Individual

##Input $1: Output location.
##Input $2: BAM file (.bam).
##Input $3: BAM file (.bam).
##More Input BAMs possible
##Output: Merged BAM file (.bam) and BAM index file.

##Usage: 
##sbatch \
##    -A ${PROJECT_ID} \
##    -o ${MYSLURMFILE} \
##    -p shared \
##    -N 1 \
##    -n 30 \
##    -t 00-10:00:00 \
##    -J BAMmerge \
##    step3-BAMmerge.sh \
##    <OUTPUT LOCATION> \
##    <INPUT BAM FILE 1> \
##    <INPUT BAM FILE 2>

############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step3-BAMmerge.sh") 

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

############################################################################
##INPUT:

OUTPUTLOCATION=$(readlink -f $1)
INPUTFILE1=$(readlink -f $2)
INPUTFILE2=$(readlink -f $3)
INPUTFILE3=$(readlink -f $4)
INPUTFILE4=$(readlink -f $5)

############################################################################
##OUTPUT:

SAMPLENAME=${INPUTFILE1##*/}
SAMPLENAME=$(echo "${SAMPLENAME}" | sed 's/\.bam.*$//' | sed 's/-job[0-9]*$//' | sed 's/_L[0-9][0-9]//')
OUTPUTFILEPREFIX=$(echo "${SAMPLENAME}.mergebam-job${JOBID}")

OUTPUTFILE1=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bam")
OUTPUTFILE2=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsbamtools.txt")
OUTPUTFILE3=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatssamtools.txt")
OUTPUTFILE4=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsindex.txt")
OUTPUTFILE5=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsgenomecoverage.txt")
OUTPUTFILE6=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.bamstatsgenomecoverageplots.txt")

############################################################################
##ACTIONS:

##Merge BAM files.
samtools merge -o ${OUTPUTFILE1} ${INPUTFILE1} ${INPUTFILE2} ${INPUTFILE3}  ${INPUTFILE4}

##Sort merged BAM file.
samtools sort -o ${OUTPUTFILE1} ${OUTPUTFILE1}

##Index merged BAM file.
samtools index -b ${OUTPUTFILE1}

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
