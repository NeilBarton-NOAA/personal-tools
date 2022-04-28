#!/bin/sh
machine=$(uname -n)
if [[ $machine == *hfe* ]]; then
    module_file=ufs_hera.intel 
    m=hera
    export HOMEDIR=/scratch1/NCEPDEV/global/$USER
    export WORKDIR=/scratch2/NCEPDEV/stmp1/$USER
elif [[ ${machine} == *Orion* ]]; then
    module_file=ufs_orion.intel
    m=orion
    export HOMEDIR=/work/noaa/global/$USER
    export WORKDIR=/work/noaa/marine/$USER
else
    echo "machine unkown: " $machine
    exit 1
fi

