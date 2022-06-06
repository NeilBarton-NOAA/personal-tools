#!/bin/sh
set -u

source $PWD/MACHINE-config.sh
####################################
#APP=ATM
#PSLOT=TEST_DA
#branch=pre_p8b
#RUN_TYPE=cycled
#IDATE=2020033100
#EDATE=2020041100

#APP=S2SW 
#PSLOT=DEV_CF_AFA
#branch=develop
#RUN_TYPE=forecast-only 
#IDATE=2012010100
#EDATE=2020041100

#APP=S2S 
APP=ATM
#APP=S2SW 
#branch=develop
branch=pre_p8b
if [[ $branch == develop ]]; then
    PSLOT=CF_ADA_DEV_${APP}
else
    PSLOT=CF_ADA_PP8B_${APP}
fi
MAIL=F
RUN_TYPE=cycled 
IDATE=2012010100
EDATE=2012010300
#IDATE=2020033100
#EDATE=2020040200
#IDATE=2020030100
#EDATE=2020030300

REPO=NeilBarton-NOAA 
CODE_DIR=${NPB_WORKDIR}/CODE/global-workflow_${branch}_${REPO}
SCRIPT_DIR=${CODE_DIR}/ush/rocoto
CONFIGDIR=${CODE_DIR}/parm/config
RESDET=384
GFS_CYC=1
COMROT=${NPB_WORKDIR}/COMROOT
EXPDIR=${NPB_WORKDIR}/EXPDIR
ICSDIR=${NPB_WORKDIR}/ICs
#ICSDIR=${NPB_WORKDIR}/ICDIR/${PSLOT}
if [[ $RUN_TYPE == forecast-only ]]; then
    EDATE=$IDATE
fi

####################################
echo " "
echo "Set up script:"
echo $SCRIPT_DIR
${SCRIPT_DIR}/setup_expt.py ${RUN_TYPE} \
--app $APP \
--pslot $PSLOT \
--configdir $CONFIGDIR \
--idate $IDATE \
--edate $EDATE \
--resdet ${RESDET:-384} \
--resens ${RESENS:-192} \
--nens ${NENS:-20} \
--cdump ${CDUMP:-gdas} \
--gfs_cyc $GFS_CYC \
--comrot $COMROT \
--expdir $EXPDIR \
--icsdir $ICSDIR
##--aerosols \

####################################
# copy restart files
COMROOT=${NPB_WORKDIR}/COMROOT/${PSLOT}
if [[ $RUN_TYPE == cycled ]]; then
    echo " "
    echo "Liking Restart Files :"
    echo "  from :" $NPB_WORKDIR/ICs/${IDATE}
    echo "  to   :" $COMROOT
    #cp -r ${NPB_WORKDIR}/ICs/${IDATE}/* ${COMROT}
    #rsync -au ${NPB_WORKDIR}/ICs/${IDATE}/* ${COMROT}
    rm -r ${COMROOT}/*
    ln -fs ${NPB_WORKDIR}/ICs/${IDATE}/* ${COMROOT}
fi

####################################
config_file=${EXPDIR}/${PSLOT}/config.base
echo " "
echo "Editing config.base file: $config_file"
sed -i 's/fv3-cpu/marine-cpu/g' ${config_file}
sed -i "s:${HOMEDIR}:${NPB_HOMEDIR}:g" ${config_file}
sed -i "s:${STMPDIR}:${NPB_STMPDIR}:g" ${config_file}
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
if [[ $MAIL == T ]]; then
    sed -i 's:MAILTO="":MAILTO="neil.barton@noaa.gov":g' $cron_file
fi

db_file=$EXPDIR/${PSLOT}/${PSLOT}.db
xml_file=$EXPDIR/${PSLOT}/${PSLOT}.xml
crontab -l | cat - $cron_file | crontab -
rocotorun -d $db_file -w $xml_file

####################################
if [[ ! -f $xml_file ]]; then
    echo "$xml_file does not exist"
    exit 1
fi
echo " "
echo "db=${db_file}"
echo "xml=${xml_file}"

