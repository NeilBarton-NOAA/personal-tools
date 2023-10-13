#!/bin/sh
set -u
source $PWD/MACHINE-config.sh
TOPDIR=$NPB_WORKDIR/CODE
mkdir -p $TOPDIR

REPO=NeilBarton-NOAA && HASH=run 
#REPO=rmontuoro && HASH=gefs/ep4
#REPO=ufs-weather-model && HASH=Prototype-P8c
#REPO=ufs-community && HASH=develop
COMPILE=T
########################
# check out code
cd $TOPDIR
CODE=ufs-weather-model_${HASH////\_}_${REPO}
if [[ ! -d ${CODE} ]]; then
    git clone https://github.com/${REPO}/ufs-weather-model.git ${CODE}
    cd ${CODE}
    git checkout ${HASH}
    git submodule update --init --recursive
else
    cd ${CODE}
fi

####################################
# The model compiles during the RT test scripts
# But if wanted to compile, use the below
####################################
# build model
if [[ ${COMPILE} == T ]]; then

module purge
[[ ${module_file} == *wcoss* ]] && module reset
module use modulefiles
module load ${module_file}

declare -A COMPILES
COMPILES=( 
["S2SWA"]="-DAPP=S2SWA -D32BIT=ON -DCCPP_SUITES=FV3_GFS_v17_coupled_p8"
#["S2SWA_64BIT"]="-DAPP=S2SWA -D32BIT=OFF -DCCPP_SUITES=FV3_GFS_v17_coupled_p8"
#["ATM"]="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"
)

for COMP in "${!COMPILES[@]}"; do
    export CMAKE_FLAGS=${COMPILES[$COMP]}
    echo "${COMP}: ${CMAKE_FLAGS}"
    bash -x ./build.sh
    mkdir -p bin
    cp build/ufs_model bin/ufs_model
    cp build/ufs_model bin/ufs_${COMP}
    echo ${PWD}
    ls -ltr bin/*

done

fi
