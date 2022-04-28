#!/bin/sh
set -u

source $PWD/MACHINE-config.sh
####################################
APP=ATM #S2SW, ATM
PSLOT=TEST_CYCLE
CODE_DIR=${WORKDIR}/global-workflow
SCRIPT_DIR=${CODE_DIR}/ush/rocoto
CONFIGDIR=${CODE_DIR}/parm/config
IDATE=2013040100
EDATE=2013041100
RES=384
GFS_CYC=1
COMROT=$WORKDIR/COMROOT
EXPDIR=$WORKDIR/EXPDIR
ICSDIR=$WORKDIR/ICDIR/${PSLOT}
#RUN_TYPE=forecast-only 
RUN_TYPE=cycled

####################################
#echo " "
#echo "Set up script:"
#${SCRIPT_DIR}/setup_expt.py ${RUN_TYPE} \
#--app $APP \
#--pslot $PSLOT \
#--configdir $CONFIGDIR \
#--idate $IDATE \
#--edate $EDATE \
#--gfs_cyc $GFS_CYC \
#--comrot $COMROT \
#--expdir $EXPDIR \
#--icsdir $ICSDIR
##--res $RES \
##--aerosols \

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
if [[ $RUN_TYPE == forecast-only ]]; then
    ${SCRIPT_DIR}/setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT
elif [[ $RUN_TYPE == cycled ]]; then
    ${SCRIPT_DIR}/setup_workflow.py --expdir $EXPDIR/$PSLOT
else
    echo "RUN_TYPE is unkwown: $RUN_TYPE"
    exit 1
fi

####################################
echo " " 
echo "start crontab:" 
crontab $EXPDIR/$PSLOT/$PSLOT.crontab

####################################
echo " "
echo "db=$EXPDIR/${PSLOT}/${PSLOT}.db"
echo "xml=$EXPDIR/${PSLOT}/${PSLOT}.xml"

