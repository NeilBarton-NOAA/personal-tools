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
RESOCN=${7:-025}
ICSDIR=${8:-$NPB_WORKDIR/ICs/${DTG}}

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

if [[ $APP == ATM || ${APP:0:3} == S2S ]]; then
    # deterministic bias files
    LINK_FILES $ICSDIR $COMROT/gdas.${DTG:0:8}/${DTG:8:10}/atmos
    # deterministic INPUT files
    LINK_FILES $ICSDIR/$RESDET/control/INPUT $COMROT/gdas.${DTG:0:8}/${DTG:8:10}/atmos/INPUT
    # ensemble files
    for mbr in $(seq -f '%03g' 1 $NENS); do
        LINK_FILES ${ICSDIR}/${RESENS}/mem${mbr}/INPUT $COMROT/enkfgdas.${DTG:0:8}/${DTG:8:10}/mem${mbr}/INPUT
    done
fi

if [[ ${APP:0:3} == S2S ]]; then
    # MOM6
    LINK_FILES ${ICSDIR}/${RESOCN}/ocn $COMROT/gdas.${DTG:0:8}/${DTG:8:10}/ocean/RESTART
    # CICE6
    LINK_FILES ${ICSDIR}/${RESOCN}/ice $COMROT/gdas.${DTG:0:8}/${DTG:8:10}/ice/RESTART
    # WAV (add when available)
fi
