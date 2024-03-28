#!/bin/sh
set -u
PSLOT=EP5dtest
MEMBERS=10
export PDY=20171004
export cyc=00

export DIRS_TO_KEEP="
model_data/ice/history 
products/atmos/grib2/0p50
products/ocean/netcdf
products/wave/gridded
products/wave/station
"

export WORKDIR=${TOPCOMROOT}
    
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
    # members
    for M in $(seq 0 ${MEMBERS}); do
        M=$(printf "%03d" ${M})
        export ens_dir=gefs.${PDY}/${cyc}/mem${M}/${D}
        export SRC=${WORKDIR}/${ens_dir}
        export DST=${KEEP_DIR}/${ens_dir}
    submit_file=rsync_${M}_${D////\_}
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

echo ${SRC}
mkdir -p ${DST}
rsync -au ${SRC}/* ${DST}

echo "DONE"
EOF
        chmod 755 ${submit_file}
        qsub ${submit_file}
        rm ${submit_file}
    done #members
done #directories




