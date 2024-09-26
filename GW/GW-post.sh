#!/bin/sh
set -u
EXP_ID=SFS_BASELINE
export TOPCOMROOT=${NPB_WORKDIR}/SFS
#export RSYNC_DIR=/lfs/h2/emc/ens/noscrub/neil.barton/RUNS

export DIRS_TO_KEEP="
model_data/ice/history 
model_data/wave/history 
products/atmos/grib2/1p00
products/atmos/grib2/0p25
products/atmos/grib2/0p50
"
if [[ ! -d ${TOPCOMROOT} ]]; then
    echo "FATAL: ${TOPCOMROOT} does not exist"
    exit 1
fi
 
################################################
################################################
################################################
DTG=1994050100
for D in $(ls -d ${TOPCOMROOT}/*/ ); do
echo ${D}
DTG=${D##*gefs.}
DTG=${DTG:0:8}00
export PDY=${DTG:0:8}
export cyc=${DTG:8:10}

for D in ${DIRS_TO_KEEP}; do
    echo ${EXP_ID} ${D}
    export SRC="gefs.${PDY}/${cyc}/*/${D}/*"
    export DES="/NCEPDEV/emc-marine/2year/${USER}/${EXP_ID}/${PDY}${cyc}_${D////\_}.tar"
    [[ -f htar.sh ]] && rm htar.sh
    name=htar${EXP_ID}${D////\_} 
    printf "#!/bin/sh\n hsi mkdir -p $(dirname ${DES})\n cd ${TOPCOMROOT}\n htar -cvf ${DES} ${SRC}" >> htar.sh
    #bash htar.sh
    sbatch -J ${name} -n 1 -t 00:30:00 -A niagara --partition=service htar.sh
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
done #DTG/DIRS
