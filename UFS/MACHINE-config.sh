#!/bin/sh
machine=$(uname -n)
# g-w options
export TOPEXPDIR=${NPB_WORKDIR}/RUNS/EXPDIR
export TOPCOMROOT=${NPB_WORKDIR}/RUNS/COMROOT
export TOPICDIR=${NPB_WORKDIR}/ICs
if [[ ${machine:0:1} == h ]]; then
    export module_file=ufs_hera.intel
    export ACCNR=marine-cpu
    m=hera.intel
elif [[ ${machine} == *[cd]login* ]]; then
    module_file=ufs_wcoss2.intel
    m=wcoss2.intel
    export ACCNR=GFS-DEV
    export TOPCOMROOT=/lfs/h2/emc/ptmp/neil.barton/COMROOT
    export BASE_CPLIC="/lfs/h2/emc/ens/noscrub/neil.barton/ICs/GW_TEST"
elif [[ ${machine} == *Orion* ]]; then
    module_file=ufs_orion.intel
    m=orion
    #defaults in scripts
    export HOMEDIR=/work/noaa/global/'${USER}'
else
    echo "in ~/UFS/MACHINE-config.sh"
    echo "machine unknown: " $machine
    exit 1
fi

