#!/bin/sh
set -u
################################################################################################
# https://github.com/ufs-community/ufs-weather-model/wiki/Running-regression-test-using-rt.sh
################################################################################################

source $PWD/MACHINE-config.sh
REPO=NeilBarton-NOAA 
CODE_DIR=$NPB_WORKDIR/CODE/ufs-weather-model_${REPO}
export RUNDIR_ROOT=${NPB_WORKDIR}/RUNs/RTs
export ACCNR=marine-cpu
source $PWD/MACHINE-config.sh
# Coupled Case
#case="
#COMPILE | -DAPP=S2SWA -DCCPP_SUITES=FV3_GFS_v17_coupled_p8,FV3_GFS_cpld_rasmgshocnsstnoahmp_ugwp  | - $m   | fv3 | 
#"
case="
RUN     | cpld_bmark_p8             |  | fv3 | 
"
# Data Atmosphere
#case="
#COMPILE | -DAPP=NG-GODAS            | - $m        | fv3 |
#RUN     | datm_cdeps_control_cfsr   | - $m        | fv3 |
#"
############
# run tests
config_file=$PWD/CONF/RUN_CASE
if [[ -f $config_file ]]; then
  rm $config_file
fi
cat << EOF > $PWD/CONF/RUN_CASE
$case
EOF
echo $case  
case=$(echo $case | cut -d'|' -f1 | sed -e 's/^ *//' -e 's/ *$//')
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
# options
#MED
export MED_tasks_cpl_bmrk=200
export MED_thrds_cpl_bmrk=1
#ATM-CHM
export INPES_cpl_bmrk=8
export JNPES_cpl_bmrk=8
export THRD_cpl_bmrk=1
#ATMIO
export WPG_cpl_bmrk=48
#OCN
export OCN_tasks_cpl_bmrk=120
export OCN_thrds_cpl_bmrk=2
#OCNIO
export MOM6_IO_LAYOUT='4,2'
#ICE
export ICE_tasks_cpl_bmrk=48
export ICE_thrds_cpl_bmrk=1
#WAV
export WAV_tasks_cpl_bmrk=80
export WAV_thrds_cpl_bmrk=1
# FCST and clock
export DAYS_SET=1
export WLCLK_dflt=120
export RESTART_N_SET=24

####################################
SUFFIX=${case}_$( date +%s )
export RT_SUFFIX=_${SUFFIX}
${CODE_DIR}/tests/rt.sh -kl ${config_file} >rt_output_${SUFFIX}.txt 2>&1 &
tail -f rt_output_${SUFFIX}.txt
