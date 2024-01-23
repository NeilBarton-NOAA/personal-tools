#!/bin/sh
set -u
########################################################################
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility
# https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/
# C96 (~100 km), C192 (~50 km), C384 (25 km), C768 (~13 km), C1152 (~9km)
####################################
# Set Top options
export DTG=2013040100
export ENS_SETTINGS=T
export FORECAST_LENGTH=16 # in days
export WALLCLOCK=$(( 15 ))
#export JOB_QUEUE=debug # batch or debug on hera
export UFS_EXEC=ufs_S2SWA 
export DEBUG=F
#REPO=ufs-community && HASH=develop
REPO=NeilBarton-NOAA && HASH=run
PATH_RUN=${NPB_WORKDIR}/CODE/ufs-weather-model_run_NeilBarton-NOAA/RUN 
RUNDIR_MPI=T

####################################
# Resolution Options
#export ATM_RES=C192
#export OCN_RES=025

####################################
# Model Options
export GOCART_NO3=F
export WAV_RES=glo_025

####################################
# Set MPI options,  if NMPI=0, model will not run
export ATM_INPES=16
export ATM_JNPES=16
export ATM_THRD=1
export CHM_NMPI=$(( ATM_INPES * ATM_JNPES * 6 ))
export OCN_NMPI=130
export ICE_NMPI=72
export WAV_NMPI=250
export WAV_THRD=1
#export MED_NMPI=300

############
# IO options                        # DEFAULTS
export ATM_WPG=48                   # 48
export MOM6_IO_LAYOUT='1,5'         # 1,1
export RESTART_FREQ=48              # restart writeout (hours, all components)
export OUTPUT_FREQ=3                # forecast length (FV3 and MOM6)
#export CICE_OUTPUT=T               # F

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH////\_}_${REPO}
export PATH_RUN=${PATH_RUN:-${UFS_HOME}/RUN}
TOP_RUNDIR=${TOP_RUNDIR:-UFS}
RUNDIR="${NPB_WORKDIR}/RUNS/${TOP_RUNDIR}"
if [[ ${DEBUG} != T ]] && [[ ${RUNDIR_MPI} == T ]]; then
[ ! -z ${ATM_INPES+x} ] && RUNDIR="${RUNDIR}_ATM_${ATM_INPES}x${ATM_JNPES}"
[ ! -z ${ATM_THRD+x} ] && RUNDIR="${RUNDIR}-${ATM_THRD}"
[ ! -z ${CHM_NMPI+x} ] && [ ${CHM_NMPI} != 0 ] && RUNDIR="${RUNDIR}_CHM_${CHM_NMPI}"
[ ! -z ${OCN_NMPI+x} ] && RUNDIR="${RUNDIR}_OCN_${OCN_NMPI}"
[ ! -z ${OCN_THRD+x} ] && RUNDIR="${RUNDIR}-${OCN_THRD}"
[ ! -z ${ICE_NMPI+x} ] && RUNDIR="${RUNDIR}_ICE_${ICE_NMPI}"
[ ! -z ${ICE_THRD+x} ] && RUNDIR="${RUNDIR}-${ICE_THRD}"
[ ! -z ${WAV_NMPI+x} ] && [ ${WAV_NMPI} != 0 ] && RUNDIR="${RUNDIR}_WAV_${WAV_NMPI}"
[ ! -z ${WAV_THRD+x} ] && [ ${WAV_NMPI} != 0 ] && RUNDIR="${RUNDIR}-${WAV_THRD}"
fi
${PATH_RUN}/UFS-submit.sh ${RUNDIR}

