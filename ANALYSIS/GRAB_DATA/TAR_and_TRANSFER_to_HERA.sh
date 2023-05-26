#!/bin/sh
set -u
TOPDIR=${NPB_WORKDIR}/DIAG
cd ${TOPDIR}
file_name=OBS.tar
tar -cvf ${file_name} *
put-to-hera ${file_name} /scratch2/NCEPDEV/stmp3/Neil.Barton/DIAG
rm ${file_name}
