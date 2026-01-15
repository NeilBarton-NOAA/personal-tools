#!/bin/bash
set -u
source ${PWD}/functions.sh && machine_config
####################################
# set up GW runs 
# https://global-workflow.readthedocs.io/en/latest/
####################################
# Code
#REPO=YangxingZheng-NOAA && HASH=sfs_products
REPO=NeilBarton-NOAA && HASH=SFS_monthly_products
#REPO=NOAA-EMC && HASH=develop
#REPO=NOAA-EMC && HASH=dev/sfs

HOMEgfs=${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}
YAML=(${HOME}/GW/YAMLS/C192mx025_S2S_CPC_ICS_TEST.yaml)
#YAML=(${HOMEgfs}/dev/ci/cases/pr/C96mx025_S2S.yaml)
#YAML=(${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2S_SCOUT_ICS.yaml)
#YAML+=(${HOMEgfs}/dev/ci/cases/pr/C96mx100_S2S.yaml)
#export TOPICDIR=${NPB_WORKDIR}/ICs 

DEFAULT_YAMLS=F
CI_FORECASTS_YAMLS=F
CI_DA_YAMLS=F 
SFS_BASELINE=F
CLONE_ONLY=F
BUILD_ONLY=F
UPDATE_CODE=F

####################################
# The work to set up an experiment
clone_gw ${HOMEgfs} ${HASH} ${REPO}
[[ ${CLONE_ONLY:-F} == T ]] && echo "Only Cloning g-w" && exit 0
[[ ${UPDATE_CODE:-F} == T ]] && update_gw ${HOMEgfs}
get_yamls ${DEFAULT_YAMLS} ${CI_FORECASTS_YAMLS} ${CI_DA_YAMLS} 
build_gw ${HOMEgfs} ${COMPUTE_ACCOUNT} ${YAML[@]}
[[ ${BUILD_ONLY:-F} == T ]] && echo "Stoping After Building g-w" && exit 0
create_experiment ${HOMEgfs} ${m} ${COMPUTE_ACCOUNT} ${YAML[@]}
link_EXPDIR ${HOMEgfs} ${YAML[@]}
[[ ${SFS_BASELINE:-F} == T ]] && sfs_baseline ${YAML[@]}
add_to_crontab ${m} ${YAML[@]}
source ~/.profile
echo " "
rocotoMONITOR

