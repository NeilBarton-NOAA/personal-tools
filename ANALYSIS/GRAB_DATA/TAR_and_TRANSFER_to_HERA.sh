#!/bin/sh
set -u
TOPDIR=${NPB_WORKDIR}/DIAG/OBS
cd ${TOPDIR}
DIRS=$(ls -d */)
for D in ${DIRS}; do
    echo ${D::-1}
    file_name=${D::-1}.tar
    tar -cvf ${file_name} ${D}/*
    put-to-hera ${file_name} /scratch2/NCEPDEV/stmp3/Neil.Barton/DIAG/OBS
    rm ${file_name}
done
