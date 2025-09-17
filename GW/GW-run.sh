#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
# https://global-workflow.readthedocs.io/en/latest/
####################################
# Code
#REPO=NOAA-EMC && HASH=develop
REPO=NeilBarton-NOAA && HASH=sfs_ICS
#REPO=XiaqiongZhou-NOAA && HASH=SFSbeta0.1
HOMEgfs=${1:-${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}}
YAML=${2:-${HOMEgfs}/workflow/GEFS_16d.yaml}
SFS_BASELINE=F
DEBUG=F
####################################
# YAMLS for SFS
YAML=${HOMEgfs}/dev/ci/cases/sfs/C96mx100_S2S_CPC_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C96mx100_S2S_REPLAY_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2S_CPC_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2S_REPLAY_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2SW_REPLAY_ICS.yaml
# PR Testing
#YAML=${HOMEgfs}/dev/ci/cases/pr/C96mx100_S2S.yaml
#YAML=${HOMEgfs}/dev/ci/cases/pr/C48_S2SWA_gefs.yaml
#YAML=${HOMEgfs}/dev/ci/cases/pr/C48_S2SW.yaml
#YAML=${HOMEgfs}/dev/ci/cases/pr/C96_atm3DVar.yaml
export pslot=${HASH}_$(basename ${YAML/.yaml*})

########################
# Check Code
echo "HOMEgfs: ${HOMEgfs}"
echo "YAML: ${YAML}"
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
[[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1

########################
# Machine Specific and Personallized options
export TOPICDIR=${NPB_WORKDIR}/ICs
export RUNTESTS=${NPB_WORKDIR}/RUNS
machine=$(uname -n)
[[ ${machine:0:3} == hfe ]] && m=hera && RUNDIRS=/scratch1/NCEPDEV/stmp2/${USER}/RUNDIRS
[[ ${machine} == *[cd]login* ]] && m=wcoss2
[[ ${machine} == *Orion* ]] && m=orion && RUNDIRS=/work/noaa/stmp/${USER}/ORION/RUNDIRS
[[ ${machine} == hercules* ]] && m=hercules && RUNDIRS=/work2/noaa/stmp/${USER}/HERCULES/RUNDIRS
[[ ${machine} == gaea* ]] && m=gaeac6 && RUNDIRS=/gpfs/f6/${COMPUTE_ACCOUNT}/world-shared/${USER}/RUNDIRS

############
# remove previous RUNDIR if it exists
if [[ -d ${RUNDIRS}/${pslot} ]]; then
    echo "Removing RUNDIR: ${RUNDIRS}/${pslot}"
    rm -rf ${RUNDIRS}/${pslot}
fi

############
# set up run
CD=$(dirname "$0")
source ${HOMEgfs}/dev/ci/platforms/config.${m/.*}
source ${HOMEgfs}/dev/ush/gw_setup.sh
export YAML_DIR=${HOMEgfs}
export HPC_ACCOUNT=${COMPUTE_ACCOUNT}
${HOMEgfs}/dev/workflow/create_experiment.py --yaml "${YAML}"
echo "FINISHED: create_experiment.py"

################################################
# if yes, add all SFS dates
[[ ${SFS_BASELINE} == T ]] && ${PWD}/SFS-add_basline_dates.sh ${PWD}/${pslot}.xml

################################################
# Soft link items into EXPDIR for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u && source ${TOPEXPDIR}/config.base && set -u
cd ${TOPEXPDIR}

ln -sf ${HOMEgfs} GW-CODE
ln -sf ${HOMEgfs}/dev/workflow/setup_xml.py .
ln -sf ${HOMEgfs}/dev/workflow/rocoto_viewer.py .
ln -sf ${HOMEgfs}/dev/parm/config ORIG_CONFIGS
ln -sf ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
ln -sf ${RUNDIRS}/${PSLOT} RUNDIRS
echo "FINISHED: soft-linking to EXPDIR"
if [[ ${DEBUG} == T ]]; then
    echo "DEBUGING, run set-up.xml in $EXPDIR" && exit 1
fi
################################################
# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
~/TOOLS/bin/add-to-crontab ${cron_file}
rocotorun -d ${db_file} -w ${xml_file}
echo "CRONTAB INFO:"
echo "machine=${machine}"
echo "cron_file=${cron_file}"
echo "db=${db_file}"
echo "xml=${xml_file}"
