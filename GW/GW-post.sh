#!/bin/sh
set -u
EXP_ID=EP5r2
DTG=2021010700
export MEMBERS=10
export PDY=${DTG:0:8}
export cyc=${DTG:8:10}
echo $PDY $cyc
#exit 1
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
    #export SRC="gefs.${PDY}/${cyc}/mem*/${D}/*"
    #export DES="/NCEPDEV/emc-marine/2year/${USER}/${EXP_ID}/${PDY}${cyc}_${D////\_}.tar"
    #hsi mkdir -p $(dirname ${DES})
    #cd ${TOPCOMROOT}
    #echo $PWD
    #htar -cvf ${DES} ${SRC}
    #exit 1
    for M in $(seq 0 ${MEMBERS}); do
        M=$(printf "%03d" ${M})
        export ens_dir=gefs.${PDY}/${cyc}/mem${M}/${D}
        export SRC=${TOPCOMROOT}/${ens_dir}
        export DST=${RSYNC_DIR}/${EXP_ID}/${ens_dir}
        echo ${SRC}
        mkdir -p ${DST}
        rsync -au ${SRC}/* ${DST}
        exit 1
    done
done
