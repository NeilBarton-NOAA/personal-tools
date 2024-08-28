#!/bin/sh
set -u
EXP_ID=LUCAS_WAVETEST
DTG=2020110100
APP=S2SW
export PDY=${DTG:0:8}
export cyc=${DTG:8:10}
export PSLOT=WAVETEST_${DTG}_${APP}
export TOPCOMROOT=/scratch2/NCEPDEV/stmp3/Neil.Barton/LUCAS_RUNS/${PSLOT}
#export RSYNC_DIR=/lfs/h2/emc/ens/noscrub/neil.barton/RUNS

export DIRS_TO_KEEP="
model_data/ice/history 
model_data/ocean/history 
model_data/wave/history 
products/atmos/grib2/1p00
products/atmos/grib2/0p25
products/atmos/grib2/0p50
products/ocean/netcdf
products/wave/gridded
"
if [[ ! -d ${TOPCOMROOT} ]]; then
    echo "FATAL: ${TOPCOMROOT} does not exist"
    exit 1
fi
 
################################################
################################################
################################################
for D in ${DIRS_TO_KEEP}; do
    echo ${PSLOT} ${D}
    export SRC="gefs.${PDY}/${cyc}/*/${D}/*"
    export DES="/NCEPDEV/emc-marine/2year/${USER}/${EXP_ID}/${PSLOT}/${PDY}${cyc}_${D////\_}.tar"
    [[ -f htar.sh ]] && rm htar.sh
    name=htar${PSLOT}${D////\_} 
    printf "#!/bin/sh\n hsi mkdir -p $(dirname ${DES})\n cd ${TOPCOMROOT}\n htar -cvf ${DES} ${SRC}" >> htar.sh
    sbatch -J ${name} -n 1 -t 04:00:00 -A marine-cpu --partition=service htar.sh
    [[ -f htar.sh ]] && rm htar.sh
#   # Go Through Each directory
#    for M in $(seq 0 ${MEMBERS}); do
#        M=$(printf "%03d" ${M})
#        export ens_dir=gefs.${PDY}/${cyc}/mem${M}/${D}
#        export SRC=${TOPCOMROOT}/${ens_dir}
#        export DST=${RSYNC_DIR}/${EXP_ID}/${ens_dir}
#        echo ${SRC}
#        mkdir -p ${DST}
#        rsync -au ${SRC}/* ${DST}
#        exit 1
#    done
done
