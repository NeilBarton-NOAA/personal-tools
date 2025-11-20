#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
# https://global-workflow.readthedocs.io/en/latest/
####################################
source ${PWD}/REPO_YAML
BUILD=F
CI_GFS=F && CI_GEFS=F && CI_SFS=F && CI_GCAPS=F
UPDATE_MODULES=F
SFS_BASELINE=F
ONLY_CHECKOUT=F

HOMEgfs=${1:-${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}}

####################################
# Clone Model if code doesn't exists
SCRIPT_DIR=$(readlink -f "$0") && SCRIPT_DIR=$(dirname ${SCRIPT_DIR})
if [[ ! -d ${HOMEgfs} ]]; then
    TOPDIR=${HOMEgfs}/../
    mkdir -p ${TOPDIR} && cd ${TOPDIR}
    git clone --recursive -b ${HASH} git@github.com:${REPO}/global-workflow.git $(basename ${HOMEgfs})
fi
[[ ${ONLY_CHECKOUT} == T ]] && exit 0

################################################
# Check if Code exist
echo "HOMEgfs: ${HOMEgfs}"
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
if [[ ${CI_GFS} != T ]] || [[ ${CI_GEFS} != T ]] || [[ ${CI_SFS} != T ]] || [[ ${CI_GCAPS} != T ]]; then
    YAML_DIR=${YAML_DIR:-$(dirname ${YAML})}
    YAML_NAME=${YAML_NAME:-$(basename ${YAML%.yaml})}
    echo "YAML: ${YAML_DIR}"
    [[ ! -d ${YAML_DIR} ]] && echo "yaml directory does not exist at ${YAML_DIR}" &&  exit 1
fi

################################################
# Machine Specific and Personalized options
export RUNTESTS=${NPB_WORKDIR}/RUNS
TOPICDIR=${NPB_WORKDIR}/ICs
machine=$(uname -n)
case ${machine} in
    *Orion*)     m=orion ;    
                 RUNDIRS=/work/noaa/stmp/${USER}/ORION/RUNDIRS ;
                 TOPICDIR=/work/noaa/marine/Yangxing.Zheng/ICs ;;
    hercules*)   m=hercules ; 
                 RUNDIRS=/work2/noaa/stmp/${USER}/HERCULES/RUNDIRS ; 
                 TOPICDIR=/work/noaa/marine/Yangxing.Zheng/ICs ;;
    gaea*)       m=gaeac6 ;   
                 RUNDIRS=/gpfs/f6/${COMPUTE_ACCOUNT}/world-shared/${USER}/RUNDIRS ;
                 TOPICDIR=/gpfs/f6/sfs-emc/proj-shared/Yangxing.Zheng/SFS/ICs ;;
    u*)          m=ursa ;     
                 RUNDIRS=/scratch4/NCEPDEV/stmp/${USER}/RUNDIRS ; 
                 TOPICDIR=/scratch4/NCEPDEV/global/Yangxing.Zheng/ICs ;;
    *[cd]login*) m=wcoss2 ;;
esac
export TOPICDIR=${TOPICDIR}

################################################
# Run Generate Workflow
OPTIONS=()
[[ ${BUILD} == T ]] && OPTIONS+=("-b")
[[ ${UPDATE_MODULES} == T ]] && OPTIONS+=("-u")
if [[ ${CI_GFS} != T ]] || [[ ${CI_GEFS} != T ]] || [[ ${CI_SFS} != T ]] || [[ ${CI_GCAPS} != T ]]; then
    OPTIONS+=('-Y') && OPTIONS+=("${YAML_DIR}")
    OPTIONS+=('-y') && OPTIONS+=("${YAML_NAME}")
else
    [[ ${CI_GFS:-T} == T ]] && OPTIONS+=("-G")
    [[ ${CI_GEFS:-T} == T ]] && OPTIONS+=("-E")
    [[ ${CI_SFS:-T} == T ]] && OPTIONS+=("-S")
    [[ ${CI_GCAPS:-T} == T ]] && OPTIONS+=("-C")
else
fi
OPTIONS+=("-D")
OPTIONS+=("-c")
cd ${HOMEgfs}/dev/workflow
echo "RUNNING: ./generate_workflows.sh ${OPTIONS[@]}"
./generate_workflows.sh "${OPTIONS[@]}" ${RUNTESTS}
cd ${SCRIPT_DIR}

################################################
# Soft link items into EXPDIR for easier development
ln -sf ${RUNTESTS}/EXPDIR .
if [[ ${CI_GFS} != T ]] || [[ ${CI_GEFS} != T ]] || [[ ${CI_SFS} != T ]] || [[ ${CI_GCAPS} != T ]]; then
    for YAML in ${YAML_NAME}; do
        TOPEXPDIR=${RUNTESTS}/EXPDIR/${YAML}
        COMROOT=${RUNTESTS}/COMROOT
        [[ ${SFS_BASELINE} == T ]] && ${SCRIPT_DIR}/SFS-add_basline_dates.sh ${TOPEXPDIR}/${YAML}.xml
        ln -sf ${HOMEgfs} ${TOPEXPDIR}/GW-CODE
        ln -sf ${HOMEgfs}/dev/workflow/rocoto_viewer.py ${TOPEXPDIR}
        ln -sf ${HOMEgfs}/dev/parm/config ${TOPEXPDIR}/ORIG_CONFIGS
        ln -sf ${COMROOT}/${YAML}/logs ${TOPEXPDIR}/LOGS_COMROOT
        ln -sf ${RUNDIRS}/${YAML} ${TOPEXPDIR}/RUNDIRS
    done
    echo "FINISHED: soft-linking to EXPDIR"
fi
rocotoMONITOR
