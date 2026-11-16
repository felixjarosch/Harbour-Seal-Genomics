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
##UMI based deduplication of aligned BAM files

##Input $1: Output location.
##Input $2: Indexed BAM file (*Aligned.sortedByCoord.out.bam).
##Output: Deduplicated BAM file (.bam), index file (.bai), log file (.log) and stats files (.tsv).

##Usage:
##sbatch \
##    -A ${PROJECT_ID} \
##    -o ${MYSLURMFILE} \
##    -p shared \
##    -N 1 \
##    -n 50 \
##    -t 00-10:00:00 \
##    -J step3-UMIdedup-${JOBID} \
##    step4-UMIdedup.sh \
##    <OUTPUT LOCATION> \
##    <INPUT BAM FILE>

############################################################################
##SCRIPT NAME:

SCRIPTNAME=$(echo "step4-UMIdedup.sh")

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
module load umi_tools

############################################################################
##INPUT:

OUTPUTLOCATION=$(readlink -f $1)
INPUTFILE=$(readlink -f $2)

INPUTFILELOCATION=${INPUTFILE%/*}
INPUTFILENAME=${INPUTFILE##*/}

############################################################################
##OUTPUT:

OUTPUTFILEPREFIX=$(echo ${INPUTFILENAME} | sed 's/\.bam.*$//' | sed 's/-job[0-9].*$//')
OUTPUTFILEPREFIX=$(echo "${OUTPUTLOCATION}/${OUTPUTFILEPREFIX}.UMIdedup-job${JOBID}")
OUTPUTFILE1=$(echo "${OUTPUTFILEPREFIX}.bam")
OUTPUTFILE2=$(echo "${OUTPUTFILEPREFIX}.log")
OUTPUTFILE3=$(echo "${OUTPUTFILEPREFIX}.bamstatsbamtools.txt")
OUTPUTFILE4=$(echo "${OUTPUTFILEPREFIX}.bamstatssamtools.txt")
OUTPUTFILE5=$(echo "${OUTPUTFILEPREFIX}.bamstatsindex.txt")
OUTPUTFILE6=$(echo "${OUTPUTFILEPREFIX}.bamstatsgenomecoverage.txt")
OUTPUTFILE7=$(echo "${OUTPUTFILEPREFIX}.bamstatsgenomecoverageplots.txt")

############################################################################
##ACTIONS:

umi_tools dedup \
	-I ${INPUTFILE} \
	-S ${OUTPUTFILE1} \
	-L ${OUTPUTFILE2} \
	--paired \
	--buffer-whole-contig \
	--output-stats=${OUTPUTFILEPREFIX} \
	--umi-separator=':'

##Sort BAM file.
samtools sort -o ${OUTPUTFILE1} ${OUTPUTFILE1}

##Index BAM file.
samtools index -b ${OUTPUTFILE1}

##General statistics.
bamtools stats -in ${OUTPUTFILE1} > ${OUTPUTFILE3}
samtools stats ${OUTPUTFILE1} > ${OUTPUTFILE4}
samtools idxstats ${OUTPUTFILE1} > ${OUTPUTFILE5}
samtools coverage ${OUTPUTFILE1} >  ${OUTPUTFILE6}

##Genome-wide coverage histogram.
samtools coverage --ascii --plot-depth --n-bins 25 ${OUTPUTFILE1} > ${OUTPUTFILE7}
echo "
Average genome-wide coverage (samtools depth): " >> ${OUTPUTFILE7}
samtools depth -a ${OUTPUTFILE1} | awk '{sum+=$3; sumsq+=$3*$3} END {print "Average coverage = ",sum/NR; print "Std. Dev. = ",sqrt(sumsq/NR - (sum/NR)**2)}' >> ${OUTPUTFILE7}

exit 0
