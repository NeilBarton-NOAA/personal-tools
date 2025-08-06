#!/bin/sh 
set -u
# https://global-workflow.readthedocs.io/en/latest/
########################
# Code to Checkout/Compile
REPO=NOAA-EMC && HASH=develop
#REPO=NeilBarton-NOAA && HASH=sfs_ICS
#REPO=XiaqiongZhou-NOAA && HASH=SFSbeta0.1
SFS=T && GEFS=F && GFS=F
COMPILE=T

########################
# check out code
code=gw_${HASH////\_}_${REPO}
TOPDIR=${NPB_WORKDIR}/CODE
mkdir -p ${TOPDIR} && cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone --recursive -b ${HASH} https://github.com/${REPO}/global-workflow.git ${code}
fi

########################
# build model
if [[ ${COMPILE} == T ]]; then
OPTIONS=""
[[ ${SFS} == T ]] && OPTIONS="${OPTIONS}sfs "
[[ ${GEFS} == T ]] && OPTIONS="${OPTIONS}gefs "
[[ ${GFS} == T ]] && OPTIONS="${OPTIONS}gfs "
echo "COMPILE OPTIONS: ${OPTIONS}"
cd ${TOPDIR}/${code}/sorc
sh link_workflow.sh
sh build_compute.sh -A ${COMPUTE_ACCOUNT} ${OPTIONS} >& ~/GW/GW_${code}_build.log &
fi
