#!/bin/sh
set -xu
TOPDIR=${NPB_WORKDIR}/DIAG/OBS
cd ${TOPDIR}
FILES=$(ls *.tar )
for f in ${FILES}; do
    tar -xvf ${f}
    htar -xvf ${ARCHIVE_HOME}/${f} ${f} 
    rm ${f}
done
