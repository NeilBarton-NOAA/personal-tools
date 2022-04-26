#!/bin/sh

TOPDIR=/work/noaa/marine/nbarton
cd $TOPDIR
machine=$(uname -n)

########################
# check out code

if [[ ! -d ufs-weather-model ]]; then
    git clone https://github.com/ufs-community/ufs-weather-model.git
    cd ufs-weather-model
    git submodule update --init --recurise
else
    cd ufs-weather-model
fi

########################
# build model
git use modulefiles
if [[ ${machine} == *Orion* ]]; then
    git load ufs_orion.intel
fi

#export CMAKE_FLAGS="-DAPP=ATM -DCCPP_SUITES=FV3_GFS_v16"
export CMAKE_FLAGS="-DAPP=S2SW -DCCPP_SUITES=FV3_GFS_2017_coupled,FV3_GFS_v15p2_coupled,FV3_GFS_v16_coupled,FV3_GFS_v16_coupled_noahmp"

./build.sh
