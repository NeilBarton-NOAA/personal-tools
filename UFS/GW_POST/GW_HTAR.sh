#!/bin/sh
set -u

SCRIPT_DIR=${PWD}
PSLOT=EP5dtest
MEMBERS=10
export PDY=20171004
export cyc=00

#model_data/ice/history 
export DIRS_TO_KEEP="
products/atmos/grib2/0p50
products/ocean/netcdf
products/wave/gridded
products/wave/station
"

export WORKDIR="/lfs/h2/emc/ptmp/neil.barton/${PSLOT}/COMROOT"
    
for D in ${DIRS_TO_KEEP}; do

export SRC="gefs.${PDY}/${cyc}/mem*/${D}/*"
export DES="/NCEPDEV/emc-marine/1year/Neil.Barton/GW/${PSLOT}/${PDY}${cyc}_${D////\_}.tar"
hsi mkdir -p $(dirname ${DES})

submit_file=htar_${D////\_}
cat <<EOF > ${submit_file}


#!/bin/sh
#PBS -N HTAR_${D////\_}
#PBS -j oe
#PBS -A GEFS-DEV
#PBS -q dev_transfer
#PBS -l select=1:ncpus=1:mem=5GB
#PBS -l walltime=4:00:00
#PBS -V
set -xu

cd ${WORKDIR}
htar -cvf ${DES} ${SRC}

EOF

chmod 755 ${submit_file}
qsub ${submit_file}
rm ${submit_file}

done




