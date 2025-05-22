#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
# https://global-workflow.readthedocs.io/en/latest/
####################################
# Code
#REPO=NOAA-EMC && HASH=develop
REPO=NeilBarton-NOAA && HASH=sfs_c6
HOMEgfs=${1:-${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}}
YAML=${2:-${HOMEgfs}/workflow/GEFS_16d.yaml}
SFS_BASELINE=F

####################################
# YAMLS for CI testing
YAML=${HOMEgfs}/dev/ci/cases/pr/C96mx100_S2S.yaml
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
machine=$(uname -n)
export TOPICDIR=${NPB_WORKDIR}/ICs
export RUNTESTS=${NPB_WORKDIR}/RUNS
ACCOUNT=marine-cpu
[[ ${machine:0:3} == hfe ]] && m=hera && RUNDIRS=/scratch1/NCEPDEV/stmp2/Neil.Barton/RUNDIRS
[[ ${machine} == *[cd]login* ]] && m=wcoss2 && ACCOUNT=GFS-DEV 
[[ ${machine} == *Orion* ]] && m=orion && RUNDIRS=/work/noaa/stmp/nbarton/ORION/RUNDIRS
[[ ${machine} == hercules* ]] && m=hercules && RUNDIRS=/work/noaa/stmp/nbarton/HERCULES/RUNDIRS
[[ ${machine} == gaea* ]] && m=gaeac6 && RUNDIRS=/gpfs/f6/scratch/Neil.Barton/sfs-emc/RUNDIRS && ACCOUNT=ira-da

if [[ ${machine} == gaea* ]] && [[ ${ACCOUNT} == sfs-cpu ]]; then
    edit_f=${HOMEgfs}/dev/workflow/hosts/gaeac6.yaml
    sed -i 's/normal/windfall/g' ${edit_f}
fi

############
# set up run
CD=$(dirname "$0")
source ${HOMEgfs}/dev/ci/platforms/config.${m/.*}
source ${HOMEgfs}/dev/ush/gw_setup.sh
export HPC_ACCOUNT=${ACCOUNT}
export YAML_DIR=${HOMEgfs}

${HOMEgfs}/dev/workflow/create_experiment.py --yaml "${YAML}" 
echo "FINISHED: create_experiment.py"

if [[ -d ${RUNDIRS}/${pslot} ]]; then
    echo "Removing RUNDIR: ${RUNDIRS}/${pslot}"
    rm -rf ${RUNDIRS}/${pslot} 
fi

################################################
# All forecasts in SFS Baseline?
if [[ ${SFS_BASELINE} == T ]]; then
    ${PWD}/SFS-add_basline_dates.sh ${PWD}/${pslot}.xml 
fi

################################################
# Soft link items into EXPDIR for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u
source ${TOPEXPDIR}/config.base
set -u
cd ${TOPEXPDIR}

#ln -sf ${RUNDIRS}/${PSLOT} RUNDIRS

ln -sf ${HOMEgfs} GW-CODE
ln -sf ${HOMEgfs}/dev/workflow/setup_xml.py . 
ln -sf ${HOMEgfs}/dev/workflow/rocoto_viewer.py .
ln -sf ${HOMEgfs}/dev/parm/config ORIG_CONFIGS
ln -sf ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
echo "FINISHED: soft-linking to EXPDIR"

################################################
# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
if [[ ${machine} == gaea* ]] || [[ ${machine} == GAEA* ]]; then
    scrontab -l | cat - ${cron_file} | scrontab -
else
    rocotorun -d ${db_file} -w ${xml_file}
    crontab -l | cat - ${cron_file} | crontab -
fi
echo "CRONTAB INFO:"
echo "machine=${machine}"
echo "cron_file=${cron_file}"
echo "db=${db_file}"
echo "xml=${xml_file}"
