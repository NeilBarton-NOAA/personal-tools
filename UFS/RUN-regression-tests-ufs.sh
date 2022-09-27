#!/bin/sh
set -u
################################################################################################
# https://github.com/ufs-community/ufs-weather-model/wiki/Running-regression-test-using-rt.sh
################################################################################################

source $PWD/MACHINE-config.sh
REPO=NeilBarton-NOAA 
CODE_DIR=$NPB_WORKDIR/CODE/ufs-weather-model_${REPO}
export RUNDIR_ROOT=${NPB_WORKDIR}/RUNs/RTs_MOM6IO
export ACCNR=marine-cpu
source $PWD/MACHINE-config.sh
# Coupled Control
#case="
#COMPILE | -DAPP=S2SWA -DCCPP_SUITES=FV3_GFS_v17_coupled_p8,FV3_GFS_cpld_rasmgshocnsstnoahmp_ugwp | - $m  | fv3 |
#RUN     | cpld_control_p8 | - $m | fv3 | 
#"

# Data Atmosphere
#case="
#COMPILE | -DAPP=NG-GODAS            | - $m        | fv3 |
#RUN     | datm_cdeps_control_cfsr   | - $m        | fv3 |
#"

# Coupled with ESMF threading
#case="
#COMPILE | -DAPP=S2SWA -DCCPP_SUITES=FV3_GFS_v17_coupled_p8,FV3_GFS_cpld_rasmgshocnsstnoahmp_ugwp  |    | fv3 | 
#RUN     | cpld_bmark_p8             |  | fv3 | 
#RUN     | cpld_bmark_esmfthreads_p8 |  | fv3 | 
#"
case="
RUN     | cpld_bmark_esmfthreads_p8 |  | fv3 |
"
#case="
#RUN     | cpld_bmark_p8             |  | fv3 | 
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
echo ${CODE_DIR}/tests/rt.sh
#ATM-MED-CHM
export INPES_cpl_bmrk=8
export JNPES_cpl_bmrk=8
export THRD_cpl_bmrk=1
#OCN
export OCN_tasks_cpl_bmrk=480
export OCN_thrds_cpl_bmrk=1
#ICE
export ICE_tasks_cpl_bmrk=48
export ICE_thrds_cpl_bmrk=1
#WAV
export WAV_tasks_cpl_bmrk=80
export WAV_thrds_cpl_bmrk=1
# FCST and clock
export DAYS=1
export WLCLK_dflt=120
export RESTART_N_SET=24
export RT_SUFFIX=_DAYS_${DAYS}_RESTART_${RESTART_N_SET}_\
ATM_$(( ${INPES_cpl_bmrk} * ${JNPES_cpl_bmrk} * 6 ))-${THRD_cpl_bmrk}_\
OCN_${OCN_tasks_cpl_bmrk}-${OCN_thrds_cpl_bmrk}_\
ICE_${ICE_tasks_cpl_bmrk}-${ICE_thrds_cpl_bmrk}_\
WAV_${WAV_tasks_cpl_bmrk}-${WAV_thrds_cpl_bmrk} 
${CODE_DIR}/tests/rt.sh -kl ${config_file} >rt_output.txt 2>&1 &
#-f 
#-r option to use with rocoto
tail -f rt_output.txt
