#!/bin/sh
set -u
########################################################################
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility
# https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/
# C96 (~100 km), C192 (~50 km), C384 (25 km), C768 (~13 km), C1152 (~9km)
####################################
# Set Top options
export TEST_NAME=C192O025
#export TEST_NAME=TEST
#export DTG=2023010106 # if no DTG, defaults to RT
#export DTG=2021032206 #C192 o025
export DTG=2019030112
#export DTG=2019030100
export ICDIR=${NPB_WORKDIR}/ICs/${DTG} 
export FV3_FIX_DIR=/scratch2/NCEPDEV/stmp1/Sanath.Kumar/my_grids
export GRID_SPEC_FILE=${PWD}/grid_spec.nc
export FORECAST_LENGTH=4 # in days
export WALLCLOCK=3
export UFS_EXEC=ufs_S2SWA 
export DEBUG=F
#export JOB_QUEUE=debug # batch or debug on hera
REPO=NeilBarton-NOAA && HASH=run
PATH_RUN=${NPB_WORKDIR}/CODE/ufs-weather-model_run_NeilBarton-NOAA/RUN 
RUNDIR_MPI=T

####################################
# Resolution Options
export ATM_RES=C192
export OCN_RES=025

####################################
# Model Options
export ENS_SETTINGS=F
export GOCART_NO3=T
export WAV_RES=glo_025

####################################
# Set MPI options,  if NMPI=0, model will not run
export ATM_INPES=6
export ATM_JNPES=12
export ATM_THRD=1
export CHM_NMPI=$(( ATM_INPES * ATM_JNPES * 6 ))
export OCN_NMPI=120
export ICE_NMPI=48
export WAV_NMPI=0
#export WAV_THRD=2
#export MED_NMPI=300

############
# IO options                        # DEFAULTS
#export ATM_WPG=6                   # 48
#export MOM6_IO_LAYOUT='3,2'        # 1,1
#export RESTART_FREQ=12             # restart writeout (hours, all components)
#export OUTPUT_FREQ=3               # forecast length (FV3 and MOM6)
export CICE_OUTPUT=T               # F

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH}_${REPO}
export PATH_RUN=${PATH_RUN:-${UFS_HOME}/RUN}
TOP_RUNDIR=${TOP_RUNDIR:-UFS}
RUNDIR="${NPB_WORKDIR}/RUNS/${TOP_RUNDIR}/${TEST_NAME}"
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

