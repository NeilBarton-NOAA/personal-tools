#!/bin/sh
source $PWD/MACHINE-config.sh
TOPDIR=$WORKDIR
cd $TOPDIR
echo $PWD
########################
# check out code

if [[ ! -d ufs-weather-model ]]; then
    git clone https://github.com/ufs-community/ufs-weather-model.git
    cd ufs-weather-model
    git submodule update --init --recursive
else
    cd ufs-weather-model
fi
echo $PWD
########################
# build model
module use modulefiles
module load ${module_file}

export CMAKE_FLAGS="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"
#export CMAKE_FLAGS="-DAPP=S2SW -DCCPP_SUITES=FV3_GFS_2017_coupled,FV3_GFS_v15p2_coupled,FV3_GFS_v16_coupled,FV3_GFS_v16_coupled_noahmp"

./build.sh
