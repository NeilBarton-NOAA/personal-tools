#!/bin/sh
set -u
########################################################################
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility
# https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/
# C96 (~100 km), C192 (~50 km), C384 (25 km), C768 (~13 km), C1152 (~9km)
####################################
# Set Top options
REPO=NeilBarton-NOAA && HASH=run
export DTG=2013040100
export ENS_SETTINGS=F
export FORECAST_LENGTH=5 # in days
export WALLCLOCK=$(( 2 * 60 ))
export JOB_QUEUE=debug # batch or debug on hera
#TOP_RUNDIR=IC_DEBUG && NAME=NEW_ICE_IC 
RUNDIR_MPI=T
export DEBUG=F
PATH_RUN=${NPB_WORKDIR}/CODE/ufs-weather-model_run_NeilBarton-NOAA/RUN 

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
export ATM_INPES=12
export ATM_JNPES=12
export ATM_THRD=2
export CHM_NMPI=$(( ATM_INPES * ATM_JNPES * 6 ))
export OCN_NMPI=130
export ICE_NMPI=120
export WAV_NMPI=280
export WAV_THRD=2
export MED_NMPI=300

############
# IO options                        # DEFAULTS
#export ATM_WPG=0 #48                   # 48
#export MOM6_IO_LAYOUT='1,5'         # 1,1
#export RESTART_FREQ=48              # restart writeout (hours, all components)
#export OUTPUT_FREQ=3                # forecast length (FV3 and MOM6)
#export CICE_OUTPUT=T               # F

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH////\_}_${REPO}
export PATH_RUN=${PATH_RUN:-${UFS_HOME}/RUN}
TOP_RUNDIR=${TOP_RUNDIR:-UFS}
if (( ${ATM_INPES} > 0 )); then
    NAME=${NAME:-ATM}
    if [ ! -z ${OCN_NMPI+x} ] && [ ! -z ${ICE_NMPI+x} ]; then
        (( ${OCN_NMPI} > 0 )) && (( ${ICE_NMPI} > 0 )) && [[ ${NAME} == 'ATM' ]] && NAME=S2S
    fi
    [ ! -z ${WAV_NMPI+x} ] && [ ${WAV_NMPI} != 0 ] && NAME="${NAME}W"
    [ ! -z ${CHM_NMPI+x} ] && [ ${CHM_NMPI} != 0 ] && NAME="${NAME}A"
fi
[ ! -z ${WAV_NMPI+x} ] && [ ${WAV_NMPI} != 0 ] && [[ ${NAME:0:3} == 'S2S' ]] && NAME="${NAME}W"
[ ! -z ${CHM_NMPI+x} ] && [ ${CHM_NMPI} != 0 ] && [[ ${NAME:0:3} == 'S2S' ]] && NAME="${NAME}A"

RUNDIR="${NPB_WORKDIR}/RUNS/${TOP_RUNDIR}/${NAME}"
RUNDIR_MPI=${RUNDIR_MPI:-F}
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
export UFS_EXEC=${UFS_EXEC:-ufs_S2SWA}
${PATH_RUN}/UFS-submit.sh ${RUNDIR}

