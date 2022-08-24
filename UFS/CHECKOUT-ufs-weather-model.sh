#!/bin/sh
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
#module purge
#module use modulefiles
#module load ${module_file}
# ATM
#export CMAKE_FLAGS="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"
# coupledmodel
#export CMAKE_FLAGS="-DAPP=S2SWA -DCCPP_SUITES=FV3_GFS_v16_coupled_nsstNoahmpUGWPv1,FV3_GFS_v17_coupled_p8"
#./build.sh
