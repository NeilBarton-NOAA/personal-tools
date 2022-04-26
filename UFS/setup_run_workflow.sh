#!/bin/sh
set -xu
####################################
APP=S2SW
PSLOT=TEST
CODE_DIR=/work/noaa/marine/nbarton/global-workflow
SCRIPT_DIR=${CODE_DIR}/ush/rocoto
CONFIGDIR=${CODE_DIR}/parm/config
IDATE=2013040100
EDATE=2013040100
RES=384
GFS_CYC=1
BASEDIR=/work/noaa/marine/$USER
COMROT=$BASEDIR/$PSLOT/COMROOT
EXPDIR=$BASEDIR/$PSLOT/EXPDIR
ICSDIR=$BASEDIR/$PSLOT/ICDIR/${PSLOT}
FORECAST_ONLY=T
exit 1
####################################
echo " "
echo "Set up script:"
${SCRIPT_DIR}/setup_expt.py forecast-only \
--app $APP \
--aerosols \
--pslot $PSLOT \
--configdir $CONFIGDIR \
--idate $IDATE \
--edate $EDATE \
--res $RES \
--gfs_cyc $GFS_CYC \
--comrot $COMROT \
--expdir $EXPDIR \
--icsdir $ICSDIR

# check file
# change ACCOUNT to marine-cpu line 15ish
vim ${EXPDIR}/${PSLOT}/config.base

echo " "
echo "setup workflow after any changes:"
${SCRIPT_DIR}/setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT

echo " " 
echo "crontab:" 
crontab $EXPDIR/$PSLOT/$PSLOT.crontab

echo " "
echo "export db=$BASEDIR/$PSLOT/EXPDIR/${PSLOT}.db"
echo "export xml=$BASEDIR/$PSLOT/EXPDIR/${PSLOT}.xml"

