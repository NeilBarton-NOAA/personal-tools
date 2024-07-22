#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
####################################
# Code
REPO=NeilBarton-NOAA && HASH=gefs_replay_ci
HOMEgfs=${1:-${NPB_WORKDIR}/CODE/global-workflow_${HASH////\_}_${REPO}}
YAML=${2:-${HOMEgfs}/ci/cases/pr/C96_S2S_gefs_replay_ics.yaml}
#export START_DATE=2021072900

########################
# Check Code
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
[[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1
echo "HOMEgfs: ${HOMEgfs}"
echo "YAML: ${YAML}"

export pslot=$(basename ${YAML/.yaml*})
CD=$(dirname "$0")
source ${CD}/MACHINE-config.sh
source ${HOMEgfs}/ci/platforms/config.${m/.*}
source ${HOMEgfs}/workflow/gw_setup.sh
echo $HPC_ACCOUNT
export HPC_ACCOUNT=${ACCNR}
${HOMEgfs}/workflow/create_experiment.py --yaml "${YAML}" 

################################################
# Soft link items into EXPDIR for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u
source ${TOPEXPDIR}/config.base
set -u
cd ${TOPEXPDIR}
ln -s ${DATAROOT} DATAROOT
ln -s ${HOMEgfs} GW-CODE
ln -s ${HOMEgfs}/parm/config ORIG_CONFIGS
ln -s ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
ln -s ${HOMEgfs}/workflow/setup_xml.py . 
ln -s ${HOMEgfs}/workflow/rocoto_viewer.py .

################################################
# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
rocotorun -d ${db_file} -w ${xml_file}
crontab -l | cat - ${cron_file} | crontab -
echo crontab file
echo "db=${db_file}"
echo "xml=${xml_file}"
