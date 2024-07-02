#!/bin/sh
set -u
EXP_ID=EP5r2
DTG=2021010700
export MEMBERS=10
export PDY=${DTG:0:10}
export cyc=${DTG:10:12}
echo $PDY $cyc

export PSLOT=${EXP_ID}_${DTG}
export TOPCOMROOT=/lfs/h2/emc/ptmp/neil.barton/${PSLOT}
export RSYNC_DIR=/lfs/h2/emc/ens/noscrub/neil.barton/RUNS

export DIRS_TO_KEEP="
model_data/ice/history 
products/atmos/grib2/0p50
products/ocean/netcdf
products/wave/gridded
products/wave/station
"
export TOPCOMROOT=${TOPCOMROOT}
export PSLOT=${PSLOT}
  
################################################
################################################
################################################
for D in ${DIRS_TO_KEEP}; do
    export SRC="gefs.${PDY}/${cyc}/mem*/${D}/*"
    export DES="/NCEPDEV/emc-marine/2year/${USER}/${PSLOT}/${PDY}${cyc}_${D////\_}.tar"
    hsi mkdir -p $(dirname ${DES})
    cd ${TOPCOMROOT}/${PSLOT}
    htar -cvf ${DES} ${SRC}
    for M in $(seq 0 ${MEMBERS}); do
        M=$(printf "%03d" ${M})
        export ens_dir=gefs.${PDY}/${cyc}/mem${M}/${D}
        export SRC=${TOPCOMROOT}/${PSLOT}/${ens_dir}
        export DST=${RSYNC_DIR}/${PSLOT}/${ens_dir}
        echo ${SRC}
        mkdir -p ${DST}
        rsync -au ${SRC}/* ${DST}
    done
done
