#!/bin/sh
set -u
source ${PWD}/functions.sh && machine_config
####################################
# set up GW runs 
# https://global-workflow.readthedocs.io/en/latest/
####################################
# Code
#REPO=YangxingZheng-NOAA && HASH=sfs_products
#REPO=XiaqiongZhou-NOAA && HASH=SFSbeta0.1
#REPO=NeilBarton-NOAA && HASH=sfs_CPC_ICs
REPO=NeilBarton-NOAA && HASH=SFS_monthly_products
#REPO=NOAA-EMC && HASH=dev/sfs
#REPO=NOAA-EMC && HASH=develop
HOMEgfs=${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}
#YAML=(${PWD}/YAMLS/C96mx100_S2S_CPC_ICS_48.yaml)
#YAML=(${HOMEgfs}/dev/ci/cases/pr/C96mx025_S2S.yaml)
#TOPICDIR=${NPB_WORKDIR}/ICs && export TOPICDIR=${TOPICDIR}
DEFAULT_YAMLS=F
CI_FORECASTS_YAMLS=T
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
for Y in ${YAML[@]}; do echo ${Y}; done
build_gw ${HOMEgfs} ${COMPUTE_ACCOUNT} ${YAML[@]}
[[ ${BUILD_ONLY:-F} == T ]] && echo "Stoping After Building g-w" && exit 0
create_experiment ${HOMEgfs} ${m} ${COMPUTE_ACCOUNT} ${YAML[@]}
link_EXPDIR ${HOMEgfs} ${YAML[@]}
[[ ${SFS_BASELINE:-F} == T ]] && sfs_baseline ${YAML[@]}
add_to_crontab ${m} ${YAML[@]}
source ~/.profile
echo " "
rocotoMONITOR

