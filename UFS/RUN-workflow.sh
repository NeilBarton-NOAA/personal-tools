#!/bin/sh
set -u

source $PWD/MACHINE-config.sh
####################################
IDATE=2020040100
#IDATE=2018030100
#IDATE=2021032200
EDATE=$( $PWD/DTG-add-time.sh $IDATE 3 ) 
#APP=ATM
APP=S2SW 
ENKF=T
#branch=pre_p8b
branch=S2SW_atmosDA
branch=${branch:-develop}
PSLOT=${ENKF}_ENKF_${APP}_IDATE_${IDATE}
if [[ $branch == develop ]]; then
    PSLOT="dev_"${PSLOT}
fi
MAIL=F
RUN_TYPE=cycled 
REPO=NeilBarton-NOAA 
CODE_DIR=${NPB_WORKDIR}/CODE/global-workflow_${branch}_${REPO}_${APP}
SCRIPT_DIR=${CODE_DIR}/ush/rocoto
CONFIGDIR=${CODE_DIR}/parm/config
#RESDET=96
#RESENS=96
#RESDET=384
#RESENS=384
GFS_CYC=0
COMROT=${NPB_WORKDIR}/RUNs/$PSLOT/COMROT
EXPDIR=${NPB_WORKDIR}/RUNs/$PSLOT #/EXPDIR
ICSDIR=${NPB_WORKDIR}/ICs
CDUMP=gdas
if [[ $CDUMP == gfs ]]; then
    EDATE=$IDATE
fi

####################################
echo " "
echo "Set up script:"
echo ${SCRIPT_DIR}/setup_expt.py
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
#if [[ $APP == ATM ]]; then
#if [[ $RUN_TYPE == cycled ]]; then
#    echo " "
#    echo "rsync restart files :"
#    echo "  from :" $NPB_WORKDIR/ICs/${IDATE}
#    dirs_sync="gdas.${IDATE:0:8}"
#    NENS=${NENS:-20} 
#    for mbr in $(seq -f '%03g' 1 $NENS); do
#        dirs_sync="$dirs_sync enkfgdas.${IDATE:0:8}/${IDATE:8:2}/atmos/mem${mbr}"
#    done
#    if [[ $APP != ATM ]]; then
#        dirs_sync="${dirs_sync} ice ocn wav"
#    fi
#    for d in $dirs_sync; do
#        folder=${NPB_WORKDIR}/ICs/${IDATE}/${d}
#        if [[ -d ${folder} ]]; then
#            echo "       :" ${folder}
#            mkdir -p ${COMROT}/${d}
#            rsync -au ${folder}/ ${COMROT}/${d}  
#        else
#            echo "ERROR: ICs not found: $folder"
#            exit 1
#        fi
#    done
#    echo "  to   :" $COMROT
#fi

####################################
config_file=${EXPDIR}/config.base
echo " "
echo "Editing config.base file: $config_file"
sed -i 's/fv3-cpu/marine-cpu/g' ${config_file}
sed -i "s:${HOMEDIR}:${NPB_HOMEDIR}/${PSLOT}:g" ${config_file}
sed -i "s:${STMPDIR}:${NPB_STMPDIR}/${PSLOT}:g" ${config_file}
sed -i 's:DOIAU="YES":DOIAU="NO":g' ${config_file}
sed -i 's:HPSS_PROJECT=emc-global:HPSS_PROJECT=emc-marine:g' ${config_file}
sed -i s:${EXPDIR}/'$PSLOT':${EXPDIR}:g ${config_file}
sed -i s:${COMROT}/'$PSLOT':${COMROT}:g ${config_file}
sed -i s:'$STMP'/RUNDIRS/'$PSLOT':'$STMP'/RUNDIRS:g ${config_file}
sed -i s:'$NOSCRUB'/archive/'$PSLOT':'$NOSCRUB'/archive:g ${config_file}
if [[ $ENKF == F ]]; then
sed -i s:'DOHYBVAR="YES":DOHYBVAR="NO"':g ${config_file}
fi
##################################
echo " "
echo "setup workflow after any changes:"
if [[ $RUN_TYPE == forecast-only ]]; then
    ${SCRIPT_DIR}/setup_workflow_fcstonly.py --expdir $EXPDIR 
elif [[ $RUN_TYPE == cycled ]]; then
    ${SCRIPT_DIR}/setup_workflow.py --expdir $EXPDIR 
else
    echo "RUN_TYPE is unkwown: $RUN_TYPE"
    exit 1
fi

####################################
echo " " 
echo "start crontab:" 
cron_file=$EXPDIR/$PSLOT.crontab
if [[ $MAIL == T ]]; then
    sed -i 's:MAILTO="":MAILTO="neil.barton@noaa.gov":g' $cron_file
fi
db_file=$EXPDIR/${PSLOT}.db
xml_file=$EXPDIR/${PSLOT}.xml
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

