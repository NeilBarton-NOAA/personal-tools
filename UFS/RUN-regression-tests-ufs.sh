#!/bin/sh
set -u
################################################################################################
# https://github.com/ufs-community/ufs-weather-model/wiki/Running-regression-test-using-rt.sh
################################################################################################

source $PWD/MACHINE-config.sh
REPO=NeilBarton-NOAA 
CODE_DIR=$NPB_WORKDIR/CODE/ufs-weather-model_${REPO}
export RUNDIR_ROOT=${NPB_WORKDIR}/RUNs/RTs/WOR
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
RUN     | cpld_bmark_esmfthreads_p8_TEST |  | fv3 |
"
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
#${CODE_DIR}/tests/rt.sh -k -l ${config_file} #>rt_output.txt 2>&1 &
${CODE_DIR}/tests/rt.sh -kl ${config_file} >rt_output.txt 2>&1 &
#-r option to use with rocoto

