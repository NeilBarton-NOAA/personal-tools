#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
####################################
# Code
REPO=NeilBarton-NOAA && HASH=gefs_replay_ci 
HOMEgfs=${1:-${NPB_WORKDIR}/CODE/global-workflow_${HASH////\_}_${REPO}}
YAML=${2:-${HOMEgfs}/ci/cases/pr/C96_S2SWA_gefs_replay_ics.yaml}
#YAML=${2:-${HOMEgfs}/ci/cases/pr/C48_ATM.yaml}
#YAML=${2:-${HOMEgfs}/ci/cases/pr/C48_S2SWA_gefs.yaml}

########################
# Check Code
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
[[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1
echo "HOMEgfs: ${HOMEgfs}"
echo "YAML: ${YAML}"

########################
# Machine Specific and Personallized options
machine=$(uname -n)
export TOPICDIR=${NPB_WORKDIR}/ICs
export RUNTESTS=${NPB_WORKDIR}/RUNS
ACCOUNT=marine-cpu
[[ ${machine:0:3} == hfe ]] && m=hera
[[ ${machine} == *[cd]login* ]] && m=wcoss2 && ACCOUNT=GFS-DEV 
[[ ${machine} == *Orion* ]] && m=orion 
[[ ${machine} == hercules* ]] && m=hercules

############
# set up run
export pslot=${HASH}_$(basename ${YAML/.yaml*})
CD=$(dirname "$0")
source ${HOMEgfs}/ci/platforms/config.${m/.*}
source ${HOMEgfs}/workflow/gw_setup.sh
export HPC_ACCOUNT=${ACCOUNT}
${HOMEgfs}/workflow/create_experiment.py --yaml "${YAML}" 

################################################
# Soft link items into EXPDIR for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u
source ${TOPEXPDIR}/config.base
set -u
cd ${TOPEXPDIR}
#ln -sf ${DATAROOT} DATAROOT
ln -sf ${HOMEgfs} GW-CODE
ln -sf ${HOMEgfs}/parm/config ORIG_CONFIGS
ln -sf ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
ln -sf ${HOMEgfs}/workflow/setup_xml.py . 
ln -sf ${HOMEgfs}/workflow/rocoto_viewer.py .

################################################
# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
rocotorun -d ${db_file} -w ${xml_file}
crontab -l | cat - ${cron_file} | crontab -
echo crontab file
echo "db=${db_file}"
echo "xml=${xml_file}"
