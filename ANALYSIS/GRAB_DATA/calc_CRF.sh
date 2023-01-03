#!/bin/sh
set -u
V=$1
E=$2
var="CRF_${V}W"
f_a="/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8${E}/D${V}WRF.nc"
f_c="/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8${E}/CSD${V}F.nc"
f_CRF="/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8${E}/${var}.nc"

cdo setname,${var}_surface -sub $f_a $f_c $f_CRF 
