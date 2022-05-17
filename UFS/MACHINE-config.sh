#!/bin/sh
machine=$(uname -n)
if [[ $machine == *hfe* ]]; then
    module_file=ufs_hera.intel 
    m=hera
    export HOMEDIR=/scratch1/NCEPDEV/global/'$USER'
    export NPB_HOMEDIR=/scratch2/NCEPDEV/stmp1/'$USER'
    export NPB_WORKDIR=/scratch2/NCEPDEV/stmp1/$USER
elif [[ ${machine} == *Orion* ]]; then
    module_file=ufs_orion.intel
    m=orion
    export HOMEDIR=/work/noaa/global/'$USER'
    export NPB_HOMEDIR=/work/noaa/marine/'$USER'
    export NPB_WORKDIR=/work/noaa/marine/$USER
else
    echo "machine unkown: " $machine
    exit 1
fi

