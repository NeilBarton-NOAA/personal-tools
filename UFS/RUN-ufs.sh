#!/bin/sh
set -u
########################################################################
#
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility
#
####################################
# Set Top options
#export DTG=2020040100 $ if no DTG, defaults to RTs
export TEST_NAME=S2S_TEST
export ATM_RES="C384"
export OCN_RES="025"
export FORECAST_LENGTH=0.25 #in days
export WALLCLOCK=$( echo "0.5 * 60" | bc )
REPO=NeilBarton-NOAA
####################################
# Set MPI options
#   if tasks = 0, model will not run
# ATM
export ATM_INPES=12
export ATM_JNPES=12
export ATM_THRD=2
export ATM_WPG=48
export CHM_NMPI=0
export OCN_NMPI=200
#export MOM6_IO_LAYOUT='4,2'
export ICE_NMPI=60
export WAV_NMPI=0
#MED (defaults to ATM)
#export MED_NMPI=20
#export MED_THRD=2

############
# other fcst options
export RESTART_N=24

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${REPO}
${UFS_HOME}/RUN/UFS-submit.sh ${NPB_WORKDIR}/RUNs/UFS/${TEST_NAME}_${OCN_NMPI}_${ICE_NMPI} #${APP} #_$( date +%s )

