#!/bin/sh
set -u
TOPDIR=${NPB_WORKDIR}/DIAG/OBS
cd ${TOPDIR}
DIRS=$(ls -d */)
for DIR in ${DIRS}; do
    echo ${DIR::-1}
    htar -cvf /NCEPDEV/emc-marine/5year/Neil.Barton/DIAG/OBS/${DIR::-1}.tar ${DIR}/ 
done
