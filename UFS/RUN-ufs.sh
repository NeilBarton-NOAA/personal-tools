#!/bin/sh
set -u
########################################################################
#
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility
#
####################################
# Set Top options
#export DTG=2020040100 $ if no DTG, defaults to RTs
export TEST_NAME=S2S
export ATM_RES="C384"
export OCN_RES="025"
export FORECAST_LENGTH=16 #in days
export WALLCLOCK=6 # in hours
export UFS_EXEC=ufs_S2SWA_mixed_mode
REPO=NeilBarton-NOAA
export DEBUG=F
####################################
# Set MPI options
#   if tasks = 0, model will not run
# ATM
export ATM_INPES=12
export ATM_JNPES=12
#export ATM_THRD=2
#export ATM_WPG=48
export CHM_NMPI=0
export OCN_NMPI=300
#export MOM6_IO_LAYOUT='4,2'
export ICE_NMPI=80
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
${UFS_HOME}/RUN/UFS-submit.sh ${NPB_WORKDIR}/RUNs/UFS/${TEST_NAME}_${ATM_INPES}${ATM_JNPES}_${OCN_NMPI}_${ICE_NMPI} #${APP} #_$( date +%s )

