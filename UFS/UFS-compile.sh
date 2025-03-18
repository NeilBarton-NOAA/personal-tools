#!/bin/sh
# remove build directory if rebuilding 
set -u
TOPDIR=${NPB_WORKDIR}/CODE
mkdir -p ${TOPDIR}
REPO=ufs-community && HASH=develop
COMPILE=T

########################
# check out code
cd ${TOPDIR}
CODE=ufs_${HASH////\_}_${REPO}
if [[ ! -d ${CODE} ]]; then
    git clone https://github.com/${REPO}/ufs-weather-model.git ${CODE}
    cd ${CODE}
    git checkout ${HASH}
    git submodule update --init --recursive
else
    cd ${CODE}
    git pull
    git submodule update --recursive --remote
fi

####################################
# The model compiles during the RT test scripts
# But if wanted to compile, use the below
####################################
# build model
if [[ ${COMPILE} == T ]]; then
RT_COMPILER=intel
source ${TOPDIR}/${CODE}/tests/detect_machine.sh
module_file=ufs_${MACHINE_ID}.${RT_COMPILER}
module purge
[[ ${module_file} == *wcoss* ]] && module reset
module use modulefiles
module load ${module_file}

#COMPILE | s2swa_32bit_pdlib  | intel | -DAPP=S2SWA -D32BIT=ON -DCCPP_SUITES=FV3_GFS_v17_coupled_p8 | | fv3 |
declare -A COMPILES
#FV3_GFS_v17_coupled_p8_ugwpv1
COMPILES=( 
["S2SWA"]="-DAPP=S2SWA -D32BIT=ON -DCCPP_SUITES=FV3_GFS_v17_coupled_p8_ugwpv1,FV3_GFS_v17_coupled_p8"
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
