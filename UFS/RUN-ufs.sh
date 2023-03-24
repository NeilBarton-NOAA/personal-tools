#!/bin/sh
set -u
########################################################################
# Run UFS model outside of workflow and slightly following RT testing, but with more flexibility

####################################
# Set Top options
TOP_RUNDIR=UFS
export TEST_NAME=TEST
#export DTG=2019120300 # if no DTG, defaults to RT
#export DTG=2013041500
#export ICDIR=/scratch2/NCEPDEV/stmp3/Neil.Barton/ICs/${DTG}
export FORECAST_LENGTH=1
export WALLCLOCK=0.5
export UFS_EXEC=ufs_S2SWA_mixed_mode
export DEBUG=F
#export JOB_QUEUE=debug # batch or debug on hera
REPO=ufs-community && HASH=GFSv17.HR1  #develop
#REPO=NeilBarton-NOAA && HASH=run
PATH_RUN=${NPB_WORKDIR}/CODE/ufs-weather-model_run_NeilBarton-NOAA/RUN 

####################################
# Set MPI options,  if NMPI=0, model will not run
export ATM_INPES=8
export ATM_JNPES=8
export ATM_THRD=2
export CHM_NMPI=0
export OCN_NMPI=220
export OCN_THRD=1
export ICE_NMPI=120
export ICE_THRD=1
export WAV_NMPI=0
#export WAV_THRD=2
export MED_NMPI=300

############
# IO options                        # DEFAULTS
#export ATM_WPG=48                  # 48
#export MOM6_IO_LAYOUT='4,2'        # 1,1
#export RESTART_FREQ=24              # restart writeout (hours, all components)
#export OUTPUT_FREQ=3               # forecast length (FV3 and MOM6)
#export DOPOST_WRITE=.true.          # .false.
#export CICE_OUTPUT=T               # F

############
# Submit Forecast
export UFS_HOME=${NPB_WORKDIR}/CODE/ufs-weather-model_${HASH}_${REPO}
export PATH_RUN=${PATH_RUN:-${UFS_HOME}/RUN}
TOP_RUNDIR=${TOP_RUNDIR:-UFS}
RUNDIR="${NPB_WORKDIR}/RUNS/${TOP_RUNDIR}/${TEST_NAME}"
[ ! -z ${ATM_INPES+x} ] && RUNDIR="${RUNDIR}_ATM_${ATM_INPES}x${ATM_JNPES}"
[ ! -z ${ATM_THRD+x} ] && RUNDIR="${RUNDIR}-${ATM_THRD}"
[ ! -z ${OCN_NMPI+x} ] && RUNDIR="${RUNDIR}_OCN_${OCN_NMPI}"
[ ! -z ${OCN_THRD+x} ] && RUNDIR="${RUNDIR}-${OCN_THRD}"
[ ! -z ${ICE_NMPI+x} ] && RUNDIR="${RUNDIR}_ICE_${ICE_NMPI}"
[ ! -z ${ICE_THRD+x} ] && RUNDIR="${RUNDIR}-${ICE_THRD}"
[ ! -z ${WAV_NMPI+x} ] && RUNDIR="${RUNDIR}_WAV_${WAV_NMPI}"
[ ! -z ${WAV_THRD+x} ] && RUNDIR="${RUNDIR}-${WAV_THRD}"
${PATH_RUN}/UFS-submit.sh ${RUNDIR}

