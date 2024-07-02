#!/bin/sh
set -u
EXP_ID=EP5r2
DTG=2021010700
export MEMBERS=10
export PDY=${DTG:0:10}
export cyc=${DTG:10:12}
echo $PDY $cyc

export PSLOT=${EXP_ID}_${DTG}
export TOPCOMROOT=/lfs/h2/emc/ptmp/neil.barton/${PSLOT}
export RSYNC_DIR=/lfs/h2/emc/ens/noscrub/neil.barton/RUNS

export DIRS_TO_KEEP="
model_data/ice/history 
products/atmos/grib2/0p50
products/ocean/netcdf
products/wave/gridded
products/wave/station
"

export TOPCOMROOT=${TOPCOMROOT}
export PSLOT=${PSLOT}
    

submt_file=htar_${PSLOT}

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

for D in ${DIRS_TO_KEEP}; do
    export SRC="gefs.${PDY}/${cyc}/mem*/${D}/*"
    export DES="/NCEPDEV/emc-marine/2year/${USER}/${PSLOT}/${PDY}${cyc}_${D////\_}.tar"
    hsi mkdir -p $(dirname ${DES})
    cd ${TOPCOMROOT}/${PSLOT}
    htar -cvf ${DES} ${SRC}
done

EOF
chmod 755 ${submit_file}
qsub ${submit_file}
#rm ${submit_file}

submit_file=rsync_${PSLOT}
cat <<EOF > ${submit_file}
#!/bin/sh
#PBS -N RSYNC_${M}_${D////\_}
#PBS -j oe
#PBS -A GEFS-DEV
#PBS -q dev
#PBS -l select=1:ncpus=1
#PBS -l walltime=1:00:00
#PBS -V
set -xu

for D in ${DIRS_TO_KEEP}; do
for M in $(seq 0 ${MEMBERS}); do
    M=$(printf "%03d" ${M})
    export ens_dir=gefs.${PDY}/${cyc}/mem${M}/${D}
    export SRC=${TOPCOMROOT}/${PSLOT}/${ens_dir}
    export DST=${RSYNC_DIR}/${PSLOT}/${ens_dir}
    echo ${SRC}
    mkdir -p ${DST}
    rsync -au ${SRC}/* ${DST}
done
done

echo "DONE"
EOF
chmod 755 ${submit_file}
qsub ${submit_file}
rm ${submit_file}
        




