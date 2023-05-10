#!/bin/sh
# WGET Data

DIR=/work/noaa/marine/nbarton/OBS/
poles='north south'
for p in ${poles}; do
    mkdir -p ${DIR}/${p}
    cd ${DIR}/${p}
    wget ftp://sidads.colorado.edu/DATASETS/NOAA/G02202_V4/${p}/aggregate/*nc
done
