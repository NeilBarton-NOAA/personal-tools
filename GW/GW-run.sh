#!/bin/bash
set -u
source ${PWD}/functions.sh && machine_config
####################################
# set up GW runs 
# https://global-workflow.readthedocs.io/en/latest/
####################################
# Code
REPO=NOAA-EMC && HASH=develop
#REPO=NOAA-EMC && HASH=dev/sfs
#REPO=NeilBarton-NOAA && HASH=SFSbeta1.1 && PSLOT_NAME='SFSBETA1.1_GFSv17ICs'
HOMEglobal=${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}

#YAMLS=(${HOME}/GW/YAMLS/C96mx100_S2S_CPC_ICS_TEST.yaml) 
#YAMLS=(${HOME}/GW/YAMLS/C192mx025_S2S_GFSV17_ICS_TEST.yaml) && export TOPICDIR=${NPB_WORKDIR}/ICs && PSLOT_NAME="TEST_GFSICS" 
#YAMLS=(${HOMEglobal}/dev/ci/cases/sfs/C192mx025_S2S_GFSV17_ICS.yaml) && export TOPICDIR=${NPB_WORKDIR}/ICs 

DEFAULT_YAMLS=F
CI_FORECASTS_YAMLS=T
CI_DA_YAMLS=T
SFS_BASELINE=F && SFS_MONTHS='03'
CLONE_ONLY=F
BUILD_ONLY=T
UPDATE_CODE=F

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
[[ ${SFS_BASELINE:-F} == T ]] && sfs_baseline ${YAML[@]} ${SFS_MONTHS}
add_to_crontab ${m} ${YAML[@]}
source ~/.profile
echo " "
rocotoMONITOR

