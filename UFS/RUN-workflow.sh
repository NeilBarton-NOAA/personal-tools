#!/bin/sh
set -u

source $PWD/MACHINE-config.sh
####################################
APP=ATM
PSLOT=TEST_DA
branch=pre_p8b

#APP=S2SW 
#PSLOT=TEST_LF
#branch=pre_develop

CODE_DIR=${NPB_WORKDIR}/CODE/global-workflow_${branch}
SCRIPT_DIR=${CODE_DIR}/ush/rocoto
CONFIGDIR=${CODE_DIR}/parm/config
IDATE=2020033100
EDATE=2020041100
RES=384
GFS_CYC=1
COMROT=${NPB_WORKDIR}/COMROOT
EXPDIR=${NPB_WORKDIR}/EXPDIR
ICSDIR=${NPB_WORKDIR}/ICDIR/${PSLOT}
#RUN_TYPE=forecast-only 
RUN_TYPE=cycled

if [[ $RUN_TYPE == forecast-only ]]; then
    EDATE=$IDATE
fi

####################################
echo " "
echo "Set up script:"
${SCRIPT_DIR}/setup_expt.py ${RUN_TYPE} \
--app $APP \
--pslot $PSLOT \
--configdir $CONFIGDIR \
--idate $IDATE \
--edate $EDATE \
--gfs_cyc $GFS_CYC \
--comrot $COMROT \
--expdir $EXPDIR \
--icsdir $ICSDIR
##--res $RES \
##--aerosols \

####################################
# copy restart files
COMROT=${NPB_WORKDIR}/COMROOT/${PSLOT}
if [[ $RUN_TYPE == cycled ]]; then
    echo " "
    echo "Copy Restart Files"
    rm -r ${COMROT}/*gdas*/
    cp -r ${NPB_WORKDIR}/ICs/${IDATE}/*gdas* ${COMROT}
fi

####################################
config_file=${EXPDIR}/${PSLOT}/config.base
echo " "
echo "Editing config.base file: $config_file"
sed -i 's/fv3-cpu/marine-cpu/g' ${config_file}
sed -i "s:${HOMEDIR}:${NPB_HOMEDIR}:g" ${config_file}
sed -i 's:DOIAU="YES":DOIAU="NO":g' ${config_file}
sed -i 's:HPSS_PROJECT=emc-global:HPSS_PROJECT=emc-marine:g' ${config_file}

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
cron_file=$EXPDIR/$PSLOT/$PSLOT.crontab
sed -i 's:MAILTO="":MAILTO="neil.barton@noaa.gov":g' $cron_file

crontab -l | cat - $cron_file | crontab -
#crontab $EXPDIR/$PSLOT/$PSLOT.crontab

####################################
echo " "
echo "db=$EXPDIR/${PSLOT}/${PSLOT}.db"
echo "xml=$EXPDIR/${PSLOT}/${PSLOT}.xml"

