#!/bin/sh
set -u

SCRIPT_DIR=${PWD}
PSLOT=EP5dgw
MEMBERS=10
export PDY=20171004
export cyc=00

export DIRS_TO_KEEP="
model_data/ice/history 
products/atmos/grib2/0p50/*
products/ocean/netcdf/*
products/wave/gridded/*
products/wave/station/*
"

export WORKDIR="/lfs/h2/emc/ptmp/neil.barton/${PSLOT}/COMROOT"
export KEEP_DIR="/lfs/h2/emc/ens/noscrub/neil.barton/RUNS/${PSLOT}"
    
for D in ${DIRS_TO_KEEP}; do
for M in $(seq 0 ${MEMBERS}); do

M=$(printf "%03d" ${M})
export ens_dir=gefs.${PDY}/${cyc}/mem${M}/${D}
export SRC=${WORKDIR}/${ens_dir}
export DST=${KEEP_DIR}/${ens_dir}

submit_file=submit_${M}_${D////\_}
cat <<EOF > ${submit_file}


#!/bin/sh
#PBS -N RSYNC_${M}_${D////\_}
#PBS -j oe
#PBS -A GEFS-DEV
#PBS -q dev
#PBS -l select=1:ncpus=1:mem=5GB
#PBS -l walltime=1:00:00
#PBS -V
set -xu

echo ${SRC}
mkdir -p ${DST}
rsync -au ${SRC}/* ${DST}

EOF

chmod 755 ${submit_file}
qsub ${submit_file}
exit 1
done
done




