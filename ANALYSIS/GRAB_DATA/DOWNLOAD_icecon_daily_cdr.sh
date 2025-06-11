#!/bin/sh
# WGET Data
DIR=${NPB_WORKDIR}/DIAG/OBS/ice_concentration/noaa_cdr
poles='north south'
for p in ${poles}; do
    mkdir -p ${DIR}/${p}
    cd ${DIR}/${p}
    wget ftp://sidads.colorado.edu/DATASETS/NOAA/G02202_V4/${p}/aggregate/seaice*daily*nc
done
