#!/bin/sh
set -u
########################################################################
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility

####################################
# Set Top options
export TEST_NAME=DEBUG_LINK #S2SW_${WAV_RES} #TEST_WARM_S2SW #_${WAV_RES}
export WAV_RES=mx025gefs # 'mx025gefs tripolar a b'
export DTG=2013041500 # if no DTG, defaults to RT
export TOP_ICDIR=/scratch2/NCEPDEV/stmp3/Neil.Barton/ICs/${DTG}
export ATM_ICDIR=${TOP_ICDIR}/atm
export OCN_ICDIR=${TOP_ICDIR}/ocn
export ICE_ICDIR=${TOP_ICDIR}/ice
export WAV_ICDIR=${TOP_ICDIR}/wav
export MED_ICDIR=${TOP_ICDIR}/med
export FORECAST_LENGTH=0.125 #14 #16 #0.25 #in days
export WALLCLOCK=0.1 #8 #1 #6 # in hours
export UFS_EXEC=ufs_S2SWA_mixed_mode
export DEBUG=F
export JOB_QUEUE=debug # batch or debug
REPO=ufs-community && HASH=c22aaad
#REPO=NeilBarton-NOAA && HASH=run
PATH_RUN=${NPB_WORKDIR}/CODE/ufs-weather-model_run_NeilBarton-NOAA/RUN 
#export FIX_METHOD='RT' # uncomment to grab static/fix files similar to RT method

####################################
# Set MPI options,  if NMPI=0, model will not run
#export ATM_INPES=8
#export ATM_JNPES=16
#export ATM_THRD=2
#export CHM_NMPI=0
#export OCN_NMPI=120
#export ICE_NMPI=72
#export WAV_NMPI=160
#export WAV_THRD=2
#export MED_NMPI=300
#export MED_THRD=${ATM_THRD}

############
# IO options                        # DEFAULTS
#export ATM_WPG=60                  # 48
#export MOM6_IO_LAYOUT='4,2'        # 1,1
#export RESTART_FREQ=24              # restart writeout (hours, all components)
#export OUTPUT_FREQ=3               # forecast length (FV3 and MOM6)
#export WRITE_DPOST=.true.          # .false.
#export CICE_OUTPUT=T               # F

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH}_${REPO}
export PATH_RUN=${PATH_RUN:-${UFS_HOME}/RUN}
RUNDIR="${NPB_WORKDIR}/RUNS/UFS/${TEST_NAME}"
[ ! -z ${ATM_INPES+x} ] && RUNDIR="${RUNDIR}_ATM_${ATM_INPES}x${ATM_JNPES}"
[ ! -z ${ATM_THRD+x} ] && RUNDIR="${RUNDIR}-${ATM_THRD}"
[ ! -z ${OCN_NMPI+x} ] && RUNDIR="${RUNDIR}_OCN_${OCN_NMPI}"
[ ! -z ${OCN_THRD+x} ] && RUNDIR="${RUNDIR}-${OCN_THRD}"
[ ! -z ${ICE_NMPI+x} ] && RUNDIR="${RUNDIR}_ICE_${ICE_NMPI}"
[ ! -z ${ICE_THRD+x} ] && RUNDIR="${RUNDIR}-${ICE_THRD}"
[ ! -z ${WAV_NMPI+x} ] && RUNDIR="${RUNDIR}_WAV_${WAV_NMPI}"
[ ! -z ${WAV_THRD+x} ] && RUNDIR="${RUNDIR}-${WAV_THRD}"
${PATH_RUN}/UFS-submit.sh ${RUNDIR}

