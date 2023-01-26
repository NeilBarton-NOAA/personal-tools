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
START=${START:-'cold'}
ICSDIR=${8:-$NPB_WORKDIR/ICs/${DTG}}

if [[ ${RESDET} == "C48" ]]; then 
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

R_DTG=$(./DTG-add-time.ksh ${DTG} -6 hours)
RPDY=${N_DTG:0:8}
RHH=${N_DTG:8:10}
if [[ ${START} == 'cold' ]]; then
    atmos_RPDY=${DTG:0:8}
    atoms_RHH=${DTG:8:10}
    atmos_dir=INPUT
else
    atmos_dir=RESTART
    atmos_RPDY=${RPDY}
    atmos_RHH=${RHH}
fi

if [[ $APP == ATM || ${APP:0:3} == S2S ]]; then
    # deterministic bias files
    LINK_FILES ${ICSDIR} ${COMROT}/gdas.${atmos_RPDY}/${atmos_RHH}/atmos
    # deterministic INPUT files
    LINK_FILES ${ICSDIR}/${RESDET}/control/INPUT ${COMROT}/gdas.${atmos_RPDY}/${atmos_RHH}/atmos/${atmos_dir}
    # ensemble files
    for mbr in $(seq -f '%03g' 1 $NENS); do
        LINK_FILES ${ICSDIR}/${RESENS}/mem${mbr}/INPUT ${COMROT}/enkfgdas.${atnis_RPDY}/${atmos_RHH}/atmos/mem${mbr}/INPUT
    done
fi

if [[ ${APP:0:3} == S2S ]]; then
    # MOM6
    LINK_FILES ${ICSDIR}/${RESOCN}/ocn $COMROT/gdas.${RPDY}/${RHH}/ocean/RESTART
    # CICE6
    LINK_FILES ${ICSDIR}/${RESOCN}/ice $COMROT/gdas.${RPDY}/${RHH}/ice/RESTART
    # WAV (add when available)
fi
