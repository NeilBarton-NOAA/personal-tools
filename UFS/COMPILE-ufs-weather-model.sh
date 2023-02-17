#!/bin/sh
set -u
source $PWD/MACHINE-config.sh
TOPDIR=$NPB_WORKDIR/CODE
mkdir -p $TOPDIR
REPO=NeilBarton-NOAA 
CODE=ufs-weather-model_${REPO}
echo $PWD
########################
# check out code
cd $TOPDIR
if [[ ! -d ${CODE} ]]; then
    git clone https://github.com/${REPO}/ufs-weather-model.git ${CODE}
    cd ${CODE}
    git submodule update --init --recursive
else
    cd ${CODE}
fi
echo $PWD

####################################
# The model compiles during the RT test scripts
# But if wanted to compile, use the below
####################################
# build model
module purge
module use modulefiles
module load ${module_file}

declare -A COMPILES
COMPILES=( 
["S2SWA"]="-DAPP=S2SWA -DCCPP_SUITES=FV3_GFS_v16_coupled_nsstNoahmpUGWPv1,FV3_GFS_v17_coupled_p8"
["S2SWA_mixed_mode"]="-DAPP=S2SWA -DCCPP_SUITES=FV3_GFS_v16_coupled_nsstNoahmpUGWPv1,FV3_GFS_v17_coupled_p8"
)
#["ATM"]="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"

for COMP in "${!COMPILES[@]}"; do
    export CMAKE_FLAGS=${COMPILES[$COMP]}
    echo "${COMP}: ${CMAKE_FLAGS}"
    ./build.sh
    mkdir -p bin
    cp build/ufs_model bin/ufs_module
    cp build/ufs_model bin/ufs_${COMP}
done

