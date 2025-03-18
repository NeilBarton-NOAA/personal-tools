#!/bin/sh
machine=$(uname -n)
# g-w options
export TOPICDIR=${NPB_WORKDIR}/ICs
export RUNTESTS=${NPB_WORKDIR}/RUNS

export ACCNR=marine-cpu
if [[ ${machine:0:3} == hfe ]]; then
    export module_file=ufs_hera.intel
elif [[ ${machine} == *[cd]login* ]]; then
    module_file=ufs_wcoss2.intel
    # changes from defaults above
    export ACCNR=GFS-DEV
elif [[ ${machine} == *Orion* ]]; then
    module_file=ufs_orion.intel
    export HOMEDIR=/work/noaa/global/'${USER}'
elif [[ ${machine} == hercules* ]]; then
    module_file=ufs_hercules.intel
    export HOMEDIR=/work/noaa/global/'${USER}'
else
    echo "in ~/UFS/MACHINE-config.sh"
    echo "machine unknown: " $machine
    exit 1
fi
export m=${module_file:4:10}
export HPC_ACCOUNT=${ACCNR}

