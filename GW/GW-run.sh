#!/bin/bash
set -u
source ${PWD}/functions.sh && machine_config
####################################
# set up GW runs 
# https://global-workflow.readthedocs.io/en/latest/
####################################
# Code
#REPO=NOAA-EMC && HASH=develop
#REPO=NOAA-EMC && HASH=dev/sfs
#REPO=NeilBarton-NOAA && HASH=SFSbeta1.1 
REPO=NeilBarton-NOAA && HASH=SFSbeta2.0 

HOMEglobal=${CODEDIR}/CODE/gw_${HASH////\_}_${REPO} && HOMEgfs=${HOMEglobal}

## YAMLS ############
YAMLS=(${HOMEglobal}/dev/ci/cases/sfsv1/C192mx025_S2S_CPC_ICS.yaml) && PSLOT_NAME="SFSbeta2.0"
#YAMLS=(${HOMEglobal}/dev/ci/cases/sfs/C192mx025_S2S_GFSV17_ICS.yaml) && PSLOT_NAME='beta1.1_GFS_ICs' && export TOPICDIR=${NPB_WORKDIR}/ICs
#YAMLS=(${HOME}/GW/YAMLS/C96mx100_S2S_CPC_ICS_TEST.yaml) 

## OPTIONS ############
export DTG_GW=1991090100
export NENS_GW=5
DEFAULT_YAMLS=F
CI_FORECASTS_YAMLS=F
CI_DA_YAMLS=F
SFS_ADDDATES=F && SFS_MONTHS='09'
CLONE_ONLY=F
BUILD_ONLY=F
UPDATE_CODE=F
START_RUN=T
####################################
# The work to set up an experiment
clone_gw ${HOMEglobal} ${HASH} ${REPO}
[[ ${CLONE_ONLY:-F} == T ]] && echo "Only Cloning g-w" && exit 0
[[ ${UPDATE_CODE:-F} == T ]] && update_gw ${HOMEglobal}
get_yamls ${DEFAULT_YAMLS} ${CI_FORECASTS_YAMLS} ${CI_DA_YAMLS} 
build_gw ${HOMEglobal} ${COMPUTE_ACCOUNT} 
[[ ${BUILD_ONLY:-F} == T ]] && echo "Stoping After Building g-w" && exit 0
create_experiment ${HOMEglobal} ${m} ${COMPUTE_ACCOUNT} ${YAML[@]} 
link_EXPDIR ${HOMEglobal} ${YAML[@]}
[[ ${SFS_ADDDATES:-F} == T ]] && sfs_addmonths ${SFS_MONTHS}
if [[ ${START_RUN:-T} == T ]]; then
    add_to_crontab ${m} ${YAML[@]}
    source ~/.profile
    rocotoMONITOR
else
    echo "edit experiment"
    echo ${PSLOT_NAME}
fi

