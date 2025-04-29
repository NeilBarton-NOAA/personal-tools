#!/bin/sh
set -u
EXP_ID=SFS_C192mx025_S2S
#export TOPCOMROOT=${NPB_WORKDIR}/${EXP_ID}
#export TOPCOMROOT=/collab2/data/Yangxing.Zheng/${EXP_ID}
export TOPCOMROOT=/collab1/data/Philip.Pegion/SFS/bcash/*.newice
export ARCHIVE_DIR="/NCEPDEV/emc-marine/2year/${USER}/${EXP_ID}" 
RUN=gefs
machine=$(uname -n)
hsi mkdir -p ${ARCHIVE_DIR}
#conf
export DIRS_TO_KEEP="
model/ocean/history 
model/ice/history 
products/atmos/grib2/1p00
products/atmos/grib2/0p25
products/atmos/grib2/0p50
"
#if [[ ! -d ${TOPCOMROOT} ]]; then
#    echo "FATAL: ${TOPCOMROOT} does not exist"
#    exit 1
#fi

#if mercury kill any current htars
#if [[ ${machine} == mfe* ]]; then
#    ps U ${USER} | grep htar | grep -v color | awk '{print $1}' | xargs kill
#fi
################################################
################################################
################################################
for D in $(ls -d ${TOPCOMROOT}/ ); do
    DDD=${D}
    DD=$(ls -d ${D}/gefs.*/)
    DTG=${DD##*${RUN}.}
    DTG=${DTG:0:8}00
    echo ${DD}
    export PDY=${DTG:0:8}
    export cyc=${DTG:8:10}
    for D in ${DIRS_TO_KEEP}; do
        export SRC="${RUN}.${PDY}/${cyc}/*/${D}/*"
        export DES="${ARCHIVE_DIR}/${PDY}${cyc}_${D////\_}.tar"
        hsi ls ${DES}.idx 2>/dev/null
        err=${?} 
        if (( ${err} > 0 )); then
            TAR=T
        else
            TAR=F
        fi
        if [[ ${TAR} == T ]]; then
            echo '  htar:' ${DES}
            if [[ ${machine} == mfe* ]]; then
                N_TASK=$( ps U ${USER} | wc -l )
                if (( ${N_TASK} > 200 )); then
                    echo "too many background tasks, will exit"
                    exit 1
                fi
                hsi -q mkdir -p $(dirname ${DES}) >&/dev/null
                cd ${TOPCOMROOT}
                nohup htar -cvf ${DES} ${SRC} > ~/htar.out 2>&1 &
            else
                [[ -f htar.sh ]] && rm htar.sh
                name=htar${EXP_ID}${D////\_} 
                printf "#!/bin/sh\n hsi mkdir -p $(dirname ${DES})\n cd ${DDD}\n htar -cvf ${DES} ${SRC}" >> htar.sh
                sbatch -J ${name} -n 1 -t 03:00:00 -A niagara --partition=service htar.sh
                [[ -f htar.sh ]] && rm htar.sh
            fi
        fi
    done
done #DTG/DIRS
