#!/bin/sh
set -u
source ${PWD}/functions.sh && machine_config
####################################
# set up GW runs 
# https://global-workflow.readthedocs.io/en/latest/
####################################
# Code
#REPO=NeilBarton-NOAA && HASH=ocnice_products
#REPO=YangxingZheng-NOAA && HASH=sfs_products
#REPO=XiaqiongZhou-NOAA && HASH=SFSbeta0.1
REPO=NOAA-EMC && HASH=dev/sfs
#REPO=NOAA-EMC && HASH=develop

CI_FORECASTS=F && CI_DA=F 
SFS_BASELINE=F
CLONE_ONLY=F

####################################
# The work to set up an experiment
HOMEgfs=${NPB_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}
clone_gw ${HOMEgfs} ${HASH} ${REPO}
[[ ${CLONE_ONLY:-F} == T ]] && echo "Only Cloning g-w" && exit 0
get_yamls T ${CI_FORECASTS} ${CI_DA} 
build_gw ${HOMEgfs} ${COMPUTE_ACCOUNT} ${YAML[@]}
create_experiment ${HOMEgfs} ${m} ${COMPUTE_ACCOUNT} ${YAML[@]}
link_EXPDIR ${HOMEgfs} ${YAML[@]}
[[ ${SFS_BASELINE:-F} == T ]] && sfs_baseline ${YAML[@]}
add_to_crontab ${m} ${YAML[@]}
source ~/.profile
echo " "
rocotoMONITOR

