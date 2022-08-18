#!/bin/sh
set -u
# Run UFS model outside or a workflow

CDATE=2020040100
APP=S2SW
REPO=NeilBarton-NOAA
branch=S2SW_atmosDA_dev
CASE="C384"
HOMEgfs=${NPB_WORKDIR}/CODE/global-workflow_${branch}_${REPO}
[[ ! -d $HOMEgfs ]] && echo "$CODE_DIR not found" && exit 1
CONFIG_DIR=${HOMEgfs}/parm/config
RUNDIR=${NPB_WORKDIR}/RUNs/UFS_${branch}

config_file=${CONFIG_DIR}/config.base
cp ${CONFIG_DIR}/config.base.emc.dyn ${config_file}
mkdir -p ${RUNDIR} && cd ${RUNDIR}

#set variables
export HOMEgfs=${HOMEgfs}
export machine="HERA"
export RUN=gfs
export CDUMP=${RUN}
#export RUN_ENVIR="emc"

export job=""
export DATA=${RUNDIR}
export CDATE=${CDATE}
export PDY=${CDATE:0:8}
export cyc=${CDATE:8:10}
export EXPDIR=${CONFIG_DIR}

#edit config.base file
sed -i "s:APP=@APP@:APP=$APP:g" ${config_file}
sed -i 's:EXPDIR="@EXPDIR@/$PSLOT"'":EXPDIR=$EXPDIR:g" ${config_file}
sed -i 's:gfs_cyc=@gfs_cyc@:gfs_cyc=0:g' ${config_file}
sed -i 's:CASE="@CASECTL@"'":CASE=$CASE:g" ${config_file}
sed -i 's:machine="@MACHINE@":machine="HERA":g' ${config_file}
sed -i "s:HOMEgfs=@HOMEgfs@:HOMEgfs=$HOMEgfs:g" ${config_file}

#vim $config_file
#exit 1
## run the model script
#sh ${HOMEgfs}/jobs/rocoto/fcst.sh

source "$HOMEgfs/ush/preamble.sh"
source $HOMEgfs/ush/load_fv3gfs_modules.sh
configs="base fcst"
for config in $configs; do
    source $CONFIG_DIR/config.$config
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

sh $HOMEgfs/scripts/exglobal_forecast.sh
# run the model script
#sh ${HOMEgfs}/jobs/rocoto/fcst.sh

