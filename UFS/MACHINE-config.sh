#!/bin/sh
machine=$(uname -n)
# g-w options
export TOPEXPDIR=${NPB_WORKDIR}/RUNS
export TOPCOMROOT=${NPB_WORKDIR}/RUNS/COMROOT
export TOPICDIR=${NPB_WORKDIR}/ICs
export ACCNR=marine-cpu
if [[ ${machine:0:3} == hfe ]]; then
    export module_file=ufs_hera.intel
    m=hera.intel
elif [[ ${machine} == *[cd]login* ]]; then
    module_file=ufs_wcoss2.intel
    m=wcoss2.intel
    # changes from defaults above
    export ACCNR=GFS-DEV
    export TOPCOMROOT=/lfs/h2/emc/ptmp/neil.barton
elif [[ ${machine} == *Orion* ]]; then
    module_file=ufs_orion.intel
    m=orion
    export HOMEDIR=/work/noaa/global/'${USER}'
elif [[ ${machine} == hercules* ]]; then
    module_file=ufs_hercules.intel
    m=hercules
    export HOMEDIR=/work/noaa/global/'${USER}'
else
    echo "in ~/UFS/MACHINE-config.sh"
    echo "machine unknown: " $machine
    exit 1
fi
export HPC_ACCOUNT=${ACCNR}
