#!/bin/sh
set -u
################################################################################################
# https://github.com/ufs-community/ufs-weather-model/wiki/Running-regression-test-using-rt.sh
################################################################################################

source ${PWD}/MACHINE-config.sh
REPO=ufs-community && HASH=GFSv17.HR1  #c22aaad #develop
CODE_DIR=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH}_${REPO}
export RUNDIR_ROOT=${NPB_WORKDIR}/RUNS/RTs
source ${PWD}/MACHINE-config.sh
# Coupled Case
case="
COMPILE | -DAPP=S2SWA -D32BIT=ON -DCCPP_SUITES=FV3_GFS_v17_coupled_p8,FV3_GFS_cpld_rasmgshocnsstnoahmp_ugwp  |   | fv3 | 
RUN     | cpld_bmark_p8_16d             |  | fv3 | 
"
#RUN     | cpld_S2S                  |  | fv3 | 
#case="
#COMPILE | -DAPP=S2SW -DCCPP_SUITES=FV3_GFS_v17_coupled_p8  | - $m   | fv3 | 
#RUN     | cpld_warmstart_c48       |  | fv3 | 
#"
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
nohup ${CODE_DIR}/tests/rt.sh -kl ${config_file} >rt_output_${SUFFIX}.txt 2>&1 &
#tail -f rt_output_${SUFFIX}.txt
