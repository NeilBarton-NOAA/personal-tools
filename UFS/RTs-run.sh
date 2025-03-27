#!/bin/bash
set -u
################################################################################################
# https://github.com/ufs-community/ufs-weather-model/wiki/Running-regression-test-using-rt.sh
################################################################################################

source ${PWD}/MACHINE-config.sh
#REPO=ufs-community && HASH=develop
REPO=NickSzapiro-NOAA && HASH=RT_bmark_gefs
CODE_DIR=${NPB_WORKDIR}/CODE/ufs_${HASH////\_}_${REPO}
export RUNDIR_ROOT=${NPB_WORKDIR}/RUNS/RTs
source ${PWD}/MACHINE-config.sh
# GEFS Case
case="
COMPILE | s2swa_32bit_pdlib_sfs  | intel | -DAPP=S2SWA -D32BIT=ON -DHYDRO=ON -DCCPP_SUITES=FV3_GFS_v17_coupled_p8_ugwpv1 -DPDLIB=ON | - noaacloud | fv3 |
RUN | cpld_control_sfs                                  | - noaacloud                          | baseline |
COMPILE | s2swa | intel | -DAPP=S2SWA -DCCPP_SUITES=FV3_GFS_v17_coupled_p8_ugwpv1 | | fv3 |
RUN | cpld_control_gefs                                 | - noaacloud                          | baseline |
RUN | cpld_restart_gefs                                 | - noaacloud                          |          | cpld_control_gefs
RUN | cpld_dcp_gefs                                     | - noaacloud                          | baseline |
"

############
# run tests
config_file=${PWD}/RUN_CASE
if [[ -f ${config_file} ]]; then
  rm ${config_file}
fi
cat << EOF > ${PWD}/RUN_CASE
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
nohup ${CODE_DIR}/tests/rt.sh -a ${ACCNR} -ekl ${config_file} >rt_output_${SUFFIX}.txt 2>&1 &
