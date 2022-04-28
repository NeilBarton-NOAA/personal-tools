#!/bin/sh
set -u

source $PWD/MACHINE-config.sh
####################################
APP=S2SW
PSLOT=TEST
CODE_DIR=${WORKDIR}/global-workflow
SCRIPT_DIR=${CODE_DIR}/ush/rocoto
CONFIGDIR=${CODE_DIR}/parm/config
IDATE=2013040100
EDATE=2013040100
RES=384
GFS_CYC=1
COMROT=$WORKDIR/COMROOT
EXPDIR=$WORKDIR/EXPDIR
ICSDIR=$WORKDIR/ICDIR/${PSLOT}
FORECAST_ONLY=T

####################################
echo " "
echo "Set up script:"
#${SCRIPT_DIR}/setup_expt.py forecast-only \
#--app $APP \
#--aerosols \
#--pslot $PSLOT \
#--configdir $CONFIGDIR \
#--idate $IDATE \
#--edate $EDATE \
#--res $RES \
#--gfs_cyc $GFS_CYC \
#--comrot $COMROT \
#--expdir $EXPDIR \
#--icsdir $ICSDIR

####################################
config_file=${EXPDIR}/${PSLOT}/config.base
echo " "
echo "Editing config.base file: $config_file"
sed -i 's/fv3-cpu/marine-cpu/g' ${config_file}
sed -i "s:${HOMEDIR}:${WORKDIR}:g" ${config_file}
echo $config_file

####################################
echo " "
echo "setup workflow after any changes:"
${SCRIPT_DIR}/setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT

####################################
echo " " 
echo "start crontab:" 
crontab $EXPDIR/$PSLOT/$PSLOT.crontab

####################################
echo " "
echo "export db=$EXPDIR/${PSLOT}/${PSLOT}.db"
echo "export xml=$EXPDIR/${PSLOT}/${PSLOT}.xml"

