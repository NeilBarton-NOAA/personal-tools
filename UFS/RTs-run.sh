#!/bin/bash
set -u
################################################################################################
# https://github.com/ufs-community/ufs-weather-model/wiki/Running-regression-test-using-rt.sh
################################################################################################

source ${PWD}/MACHINE-config.sh
#REPO=NeilBarton-NOAA && HASH=run
REPO=ufs-community && HASH=develop
CODE_DIR=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH////\_}_${REPO}
export RUNDIR_ROOT=${NPB_WORKDIR}/RUNS/RTs
source ${PWD}/MACHINE-config.sh
#export COMPILE_QUEUE=debug
# Coupled Case
# hera doesn't need the - $machine
# wcoss2 may need - $machine
case="
COMPILE | s2swa_32bit  | intel | -DAPP=S2SWA -D32BIT=ON -DCCPP_SUITES=FV3_GFS_v17_coupled_p8 | + wcoss2 hera orion | fv3 |
RUN | cpld_bmark_p8                               | + hera orion cheyenne wcoss2 acorn | baseline |
"

############
# run tests
config_file=${PWD}/CONF/RUN_CASE
if [[ -f ${config_file} ]]; then
  rm ${config_file}
fi
cat << EOF > ${PWD}/CONF/RUN_CASE
${case}
EOF
echo ${case}  
case=$(echo ${case} | cut -d'|' -f1 | sed -e 's/^ *//' -e 's/ *$//')
if [[ ${case} == "COMPILE" ]]; then
    echo ${CODE_DIR} $module_file
    TOPDIR=${PWD}
    cd ${CODE_DIR}
    module purge
    module use modulefiles
    module load ${module_file}
    cd ${TOPDIR}
fi

echo ${CODE_DIR}/tests/rt.sh

####################################
SUFFIX=${case}_$( date +%s )
export RT_SUFFIX=_${SUFFIX}
#nohup ${CODE_DIR}/tests/rt.sh -kl ${config_file} >rt_output_${SUFFIX}.txt 2>&1 &
nohup ${CODE_DIR}/tests/rt.sh -a ${ACCNR} -kl ${config_file} >rt_output_${SUFFIX}.txt 2>&1 &
