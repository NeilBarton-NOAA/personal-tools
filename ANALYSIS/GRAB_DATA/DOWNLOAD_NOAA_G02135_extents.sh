#!/bin/sh
# WGET Data
DIR=${NPB_WORKDIR}/DIAG/OBS/ice_extent/noaa_g02135
poles='north south'
for p in ${poles}; do
    mkdir -p ${DIR}/${p}
    cd ${DIR}/${p}
    wget -r -nd --no-check-certificate --reject "index.html*" -np -e robots=off -A "*daily*.csv" https://noaadata.apps.nsidc.org/NOAA/G02135/${p}/daily/data/
done
