#!/bin/sh
machine=$(uname -n)
if [[ ${machine:0:1} == h ]]; then
    export module_file=ufs_hera.intel 
    m=hera
    #defaults in scripts
    export HOMEDIR=/scratch1/NCEPDEV/global/'${USER}'
    export STMPDIR=/scratch1/NCEPDEV/stmp2/'${USER}'
elif [[ ${machine} == *Orion* ]]; then
    module_file=ufs_orion.intel
    m=orion
    #defaults in scripts
    export HOMEDIR=/work/noaa/global/'${USER}'
    export STMPDIR=/work/noaa/stmp/'${USER}'
elif [[ ${machine} == *[cd]login* ]]; then
    module_file=ufs_wcoss2.intel
    export HOMEDIR=/lfs/h2/emc/global/noscrub/'${USER}'
    m=wcoss2.intel
else
    echo "machine unkown: " $machine
    exit 1
fi

