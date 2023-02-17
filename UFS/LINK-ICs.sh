#!/bin/bash
########################
# Link ICs to COMROOT
########################
set -u
DTG=$1
COMROT=$2
APP=${3:-S2SW}
RESDET="C${4:-384}" 
RESENS="C${5:-192}" 
NENS=${6:-20}
START=${7:-'warm'}
ICSDIR=${8:-$NPB_WORKDIR/ICs}

if [ "${RESDET}" = "C48" ]; then 
    RESOCN=${RESOCN:-500}
else
    RESOCN=${RESOCN:-025}
fi
echo "LINKING ICs to $COMROT"
echo "  APP=${APP}"

LINK_FILES() {
  SRCDIR=$1
  DESDIR=$2
  nfiles=$( find $SRCDIR -maxdepth 1 -type f 2> /dev/null | wc -l ) 
  if (( $nfiles == 0 )); then
    echo "no files in $SRCDIR"
    exit 1
  fi
  mkdir -p $DESDIR && cd $DESDIR
  files=$( find $SRCDIR -maxdepth 1 -type f )
  ln -sf $files .
}

COLD_HOUR=${DTG:8:10}
COLD_YMD=${DTG:0:8}
WARM_DTG=$(./DTG-add-time.sh ${DTG} -6 hours)
WARM_HOUR=${WARM_DTG:8:10}
WARM_YMD=${WARM_DTG:0:8}
if [ "${START}" = "cold" ]; then
    atmos_YMD=${DTG:0:8}
    atmos_HOUR=${DTG:8:10}
    atmos_dir=INPUT
else
    atmos_YMD=${WARM_YMD}
    atmos_HOUR=${WARM_HOUR}
    atmos_dir=RESTART
fi

if [[ $APP == ATM || ${APP:0:3} == S2S ]]; then
    # deterministic INPUT files
    LINK_FILES ${ICSDIR}/gfs.${atmos_YMD}/${atmos_HOUR}/atmos/${atmos_dir} ${COMROT}/gdas.${atmos_YMD}/${atmos_HOUR}/atmos/${atmos_dir}
    # ensemble files
    for mbr in $(seq -f '%03g' 1 $NENS); do
        LINK_FILES ${ICSDIR}/enkfgdas.${atmos_YMD}/${atmos_HOUR}/atmos/mem${mbr}/${atmos_dir} ${COMROT}/enkfgdas.${atmos_YMD}/${atmos_HOUR}/mem${mbr}/atmos/${atmos_dir}
    done
    # deterministic bias files
    ln -s ${ICSDIR}/bias_files/*${COLD_HOUR}* ${COMROT}/gdas.${atmos_YMD}/${atmos_HOUR}/atmos
fi

if [[ ${APP:0:3} == S2S ]]; then
    # MOM6
    LINK_FILES ${ICSDIR}/gfs.${WARM_YMD}/${WARM_HOUR}/ocean/RESTART ${COMROT}/gdas.${WARM_YMD}/${WARM_HOUR}/ocean/RESTART
    # CICE6
    LINK_FILES ${ICSDIR}/gfs.${WARM_YMD}/${WARM_HOUR}/ice/RESTART ${COMROT}/gdas.${WARM_YMD}/${WARM_HOUR}/ice/RESTART
    # WAV (add when available)
    if [[ ${START} == warm ]]; then
        LINK_FILES ${ICSDIR}/gfs.${WARM_YMD}/${WARM_HOUR}/med/RESTART ${COMROT}/gdas.${WARM_YMD}/${WARM_HOUR}/med/RESTART
    fi
fi
