#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
####################################
# Code
REPO=NeilBarton-NOAA && HASH=SFS 
HOMEgfs=${1:-${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}}
YAML=${2:-${HOMEgfs}/ci/cases/sfs/C96mx100_S2S.yaml}

####################################
# YAMLS for CI testing
#YAML=${HOMEgfs}/ci/cases/pr/C96_S2SWA_gefs_replay_ics.yaml
YAML=${HOMEgfs}/ci/cases/pr/C48_S2SWA_gefs.yaml
#YAML=${HOMEgfs}/ci/cases/pr/C48_S2SW.yaml
#YAML=${HOMEgfs}/ci/cases/pr/C96_atm3DVar.yaml

export pslot=${HASH}_$(basename ${YAML/.yaml*})
SFS_BASELINE=F
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
[[ ${machine:0:3} == hfe ]] && m=hera && RUNDIRS=/scratch1/NCEPDEV/stmp2/Neil.Barton/RUNDIRS
[[ ${machine} == *[cd]login* ]] && m=wcoss2 && ACCOUNT=GFS-DEV 
[[ ${machine} == *Orion* ]] && m=orion && RUNDIRS=/work/noaa/stmp/nbarton/ORION/RUNDIRS
[[ ${machine} == hercules* ]] && m=hercules && RUNDIRS=/work/noaa/stmp/nbarton/HERCULES/RUNDIRS

############
# set up run
CD=$(dirname "$0")
source ${HOMEgfs}/ci/platforms/config.${m/.*}
source ${HOMEgfs}/workflow/gw_setup.sh
export HPC_ACCOUNT=${ACCOUNT}
export YAML_DIR=${HOMEgfs}

${HOMEgfs}/workflow/create_experiment.py --yaml "${YAML}" 
echo "FINISHED: create_experiment.py"

################################################
# Soft link items into EXPDIR for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u
source ${TOPEXPDIR}/config.base
set -u
cd ${TOPEXPDIR}
ln -sf ${RUNDIRS}/${PSLOT} RUNDIRS
ln -sf ${HOMEgfs} GW-CODE
ln -sf ${HOMEgfs}/parm/config ORIG_CONFIGS
ln -sf ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
ln -sf ${HOMEgfs}/workflow/setup_xml.py . 
ln -sf ${HOMEgfs}/workflow/rocoto_viewer.py .
echo "FINISHED: soft-linking to EXPDIR"

################################################
# All forecasts in SFS Baseline?
if [[ ${SFS_BASELINE} == T ]]; then
    f=${TOPEXPDIR}/*xml
    echo ${f}
    line=$(grep -n 'cycledef group' ${f} | cut -d: -f1) 
    sed -i ${line}d $f
    MONTHS="05 11"
    for Y in $(seq 1994 2023); do
        for M in ${MONTHS}; do 
            text="<cycledef group='"gefs"'>${Y}${M}010000 ${Y}${M}010000 24:00:00</cycledef>"
            sed -i "${line} i   ${text}" ${f}
            line=$(( line + 1))
        done
    done
fi

################################################
# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
rocotorun -d ${db_file} -w ${xml_file}
crontab -l | cat - ${cron_file} | crontab -
echo "CRONTAB INFO:"
echo "db=${db_file}"
echo "xml=${xml_file}"
