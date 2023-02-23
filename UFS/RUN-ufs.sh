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
export WALLCLOCK=5 # in hours
export UFS_EXEC=ufs_S2SWA_mixed_mode
REPO=NeilBarton-NOAA
branch=run
export DEBUG=F
####################################
# Set MPI options,  if NMPI=0, model will not run
export ATM_INPES=16
export ATM_JNPES=16
export ATM_THRD=1
export CHM_NMPI=0
export OCN_NMPI=220
export ICE_NMPI=320
export WAV_NMPI=0
#MED (defaults to ATM)
export MED_NMPI=300
export MED_THRD=${ATM_THRD}

############
# IO options                          defaults
#export ATM_WPG=60                  # 48
#export MOM6_IO_LAYOUT='4,2'        # 1,1
#export RESTART_FREQ=3              # forecast length
#export OUTPUT_FREQ=3               # forecast length
#export WRITE_DPOST=.true.          # .false.
#export CICE_OUTPUT=T               # F

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${branch}_${REPO}
# run script
${UFS_HOME}/RUN/UFS-submit.sh ${NPB_WORKDIR}/RUNs/UFS/\
${TEST_NAME}_\
ATM_${ATM_INPES}${ATM_JNPES}-${ATM_THRD}_\
OCN_${OCN_NMPI}_\
ICE_${ICE_NMPI}
#ATMIO_${ATM_WPG}_\
#RESTART_N_${RESTART_FREQ} #_\
#$( date +%s )

