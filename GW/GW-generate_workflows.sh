#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
# https://global-workflow.readthedocs.io/en/latest/
####################################
source ${PWD}/REPO
HOMEgfs=${1:-${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}}
BUILD=F
CI_TESTING=T
UPDATE_MODULES=F
SFS_BASELINE=F

################################################
# Check if Code exist
echo "HOMEgfs: ${HOMEgfs}"
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
if [[ ${CI_TESTING} != T ]]; then
    echo "YAML: ${YAML}"
    [[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1
fi

####################################
# Clone Model if code doesn't exists
TOPDIR=${HOMEgfs}/../
mkdir -p ${TOPDIR} && cd ${TOPDIR}
if [[ ! -d ${HOMEgfs} ]]; then
    git clone --recursive -b ${HASH} git@github.com:${REPO}/global-workflow.git ${code}
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
OPTIONS=""
[[ ${BUILD} == T ]] && OPTIONS=${OPTIONS}" -b"
[[ ${UPDATE_MODULES} == T ]] && OPTIONS=${OPTIONS}" -u"
if [[ ${CI_TESTING} == T ]]; then
    # G: GFS, E: GEFS, S: SFS, C:GCAPS
    OPTIONS=${OPTIONS}" -G -E -S -C"
else
    YAML_DIR=$(dirname ${YAML})
    YAML_NAME=$(basename ${YAML})
    OPTIONS=${OPTOINS}" -Y $(dirname ${YAML_DIR}) -y $(basename ${YAML_NAME})"
fi
OPTIONS=${OPTIONS}" -D -c -H ${HOMEgfs}"
cd ${HOMEgfs}/dev/workflow
echo "RUNNING: ./generate_workflows.sh ${OPTIONS}"
./generate_workflows.sh ${OPTIONS}

################################################
# if yes, add all SFS dates
[[ ${SFS_BASELINE} == T ]] && ${PWD}/SFS-add_basline_dates.sh ${PWD}/${pslot}.xml

################################################
# Soft link items into EXPDIR for easier development
ln -sf ${RUNTESTS}/EXPDIR .
if [[ ${CI_TESTING} != T ]]; then
    TOPEXPDIR=${RUNTESTS}/EXPDIR/${YAML_NAME}
    set +u && source ${TOPEXPDIR}/config.base && set -u
    cd ${TOPEXPDIR}
    ln -sf ${HOMEgfs} GW-CODE
    ln -sf ${HOMEgfs}/dev/workflow/rocoto_viewer.py .
    ln -sf ${HOMEgfs}/dev/parm/config ORIG_CONFIGS
    ln -sf ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
    ln -sf ${RUNDIRS}/${PSLOT} RUNDIRS
    echo "FINISHED: soft-linking to EXPDIR"
fi
rocotoMONITOR
