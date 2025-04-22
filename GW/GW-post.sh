#!/bin/sh
set -u
EXP_ID=SFS_C96mx100_S2S
export TOPCOMROOT=${NPB_WORKDIR}/${EXP_ID}
export ARCHIVE_DIR="/NCEPDEV/emc-marine/2year/${USER}/${EXP_ID}" 
hsi mkdir -p ${ARCHIVE_DIR}

export DIRS_TO_KEEP="
model/ocean/history 
model/ice/history 
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
for D in $(ls -d ${TOPCOMROOT}/*01/ ); do
    echo ${D}
    DTG=${D##*gefs.}
    DTG=${DTG:0:8}00
    export PDY=${DTG:0:8}
    export cyc=${DTG:8:10}

    for D in ${DIRS_TO_KEEP}; do
        echo ${EXP_ID} ${D}
        export SRC="gefs.${PDY}/${cyc}/*/${D}/*"
        export DES="${ARCHIVE_DIR}/${PDY}${cyc}_${D////\_}.tar"
        [[ -f htar.sh ]] && rm htar.sh
        name=htar${EXP_ID}${D////\_} 
        printf "#!/bin/sh\n hsi mkdir -p $(dirname ${DES})\n cd ${TOPCOMROOT}\n htar -cvf ${DES} ${SRC}" >> htar.sh
        sbatch -J ${name} -n 1 -t 03:00:00 -A niagara --partition=service htar.sh
        [[ -f htar.sh ]] && rm htar.sh
    done
done #DTG/DIRS
