#!/bin/sh
set -u
########################################################################
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility
# https://ufs-weather-model.readthedocs.io/en/ufs-v2.0.0/
# C96 (~100 km), C192 (~50 km), C384 (25 km), C768 (~13 km), C1152 (~9km)
####################################
# Set Top options
#export DTG=2017100503
#export DTG=2013040200
export DTG=2013040100
export ICDIR=/scratch2/NCEPDEV/stmp3/Neil.Barton/RUNS/RTs/rt_304936/cpld_bmark_p8_intel
#export ICDIR=${NPB_WORKDIR}/ICs/${DTG} 
export CICE_OUTPUT=T
export ENS_SETTINGS=T
#export CICE_RESTART='.false.'
#export ice_ic='default'
export TOP_RUNDIR=MED_TESTING
#DIFF=0.05
#ICE=${DIFF}
export TEST_NAME=RT
#EDGE_${DIFF}_ENS3
#export ice_ic=${ICDIR}/iced.2017-10-05-10800.nc
#export ice_ic=${ICDIR}/newIC_${DIFF}_iced.2017-10-05-10800.nc
#export ice_ic=${ICDIR}/newIC_EDGE_Thickness${DIFF}_iced.2017-10-05-10800.nc
#export ice_ic=${ICDIR}/newIC_EDGE_${DIFF}_iced.2017-10-05-10800.nc
#export ice_ic=${ICDIR}/newIC_THICKNESSDIFF_${DIFF}_ICE_0.05_iced.2017-10-05-10800.nc
#export ice_ic=${ICDIR}/testIC.nc
#export ice_ic=${ICDIR}/philCICEic2.nc
#export ice_ic=${ICDIR}/newIC_DIFFlimit_0.15_old_iced.2017-10-05-10800.nc
#export TEST_NAME=DEV_TEST
#export TEST_NAME=REPLAY_TEST_S2SWA_EP4_ORIG_LIMIT015_ENS3_${DTG}
#export TEST_NAME=TEST 
export FORECAST_LENGTH=16 # in days
export WALLCLOCK=360
#export JOB_QUEUE=debug # batch or debug on hera
export UFS_EXEC=ufs_S2SWA 
export DEBUG=F
#REPO=ufs-community && HASH=develop
#REPO=NeilBarton-NOAA && HASH=run
REPO=rmontuoro && HASH=gefs/ep4_newCICE
#REPO=rmontuoro && HASH=gefs/ep4/newCICE
PATH_RUN=${NPB_WORKDIR}/CODE/ufs-weather-model_run_NeilBarton-NOAA/RUN 
RUNDIR_MPI=F

####################################
# Resolution Options
#export ATM_RES=C192
#export OCN_RES=025

####################################
# Model Options
export GOCART_NO3=F
export WAV_RES=glo_025
#export GRID_SPEC_FILE=${PWD}/grid_spec.nc
#export FV3_FIX_DIR=/scratch2/NCEPDEV/stmp1/Sanath.Kumar/my_grids

####################################
# Set MPI options,  if NMPI=0, model will not run
export ATM_INPES=8
export ATM_JNPES=8
export ATM_THRD=2
#export CHM_NMPI=$(( ATM_INPES * ATM_JNPES * 6 ))
export OCN_NMPI=130
export ICE_NMPI=72
export WAV_NMPI=0 #262
#export WAV_THRD=1
#export MED_NMPI=300

############
# IO options                        # DEFAULTS
#export ATM_WPG=6                   # 48
#export MOM6_IO_LAYOUT='3,2'        # 1,1
#export RESTART_FREQ=1             # restart writeout (hours, all components)
#export OUTPUT_FREQ=3               # forecast length (FV3 and MOM6)
#export CICE_OUTPUT=T               # F

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH////\_}_${REPO}
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

