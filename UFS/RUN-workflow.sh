#!/bin/sh
####################################
# Run Script for seeting up global-worflow
#   defaults to NeilBarton-NOAA branch for specific options
####################################
set -u
source $PWD/MACHINE-config.sh

####################################
IDATE=2020040100
EDATE=$( $PWD/DTG-add-time.sh $IDATE 3 ) 
#branch=S2SW_atmosDA_dev # default is develop
branch=develop
ENKF=T
APP=S2SW
APP=ATM
#CDUMP=gfs
IAU=T
#PSLOT=${APP}_IAU${IAU}
PSLOT=${APP}_ENKF_IAU${IAU}

####################################
# Sub-Components of script
RUN_SETUP_EXPT=T
RUN_LINK_ICs=T
RUN_EDIT_CONFIG=T
RUN_SETUP_XML=T
RUN_CRONTAB=T

########################
# defaults
APP=${APP:-S2SW} 
RESDET=${RESDET:-384} 
RESENS=${RESENS:-192} 
REPO=${REPO:-NeilBarton-NOAA}
NENS=${NENS:-20} 
GFS_CYC=${GFS_CYC:-0}
ENKF=${ENKF:-T}
IAU=${IAU:-T}
PSLOT=${PSLOT:-${ENKF}_ENKF_${APP}_IDATE_${IDATE}}
branch=${branch:-develop}
CODE_DIR=${CODE_DIR:-${NPB_WORKDIR}/CODE/global-workflow_${branch}_${REPO}}
CDUMP=${CDUMP:-gdas} 
RUN_TYPE=${RUN_TYPE:-cycled} 
[[ $CDUMP == gfs ]] && RUN_TYPE=forecast-only
[[ $RUN_TYPE == forecast-only ]] && EDATE=$IDATE
SCRIPT_DIR=${CODE_DIR}/workflow

####################################
# personalized options
ICSDIR=${NPB_WORKDIR}/ICs
NPB_HOMEDIR=${NPB_WORKDIR}/RUNs
EXPDIR=${NPB_HOMEDIR}/$PSLOT 
COMROT=${NPB_HOMEDIR}/$PSLOT/COMROT
RUNDIR=${NPB_HOMEDIR}/$PSLOT/RUNDIR
MAIL=F

####################################
# check for code
if [[ ! -d $CODE_DIR ]]; then
    echo "code is not at $CODE_DIR"
    exit 1
fi

####################################
# setup_expt.py script
if [[ $RUN_SETUP_EXPT == T ]]; then

echo " "
echo "Set up script:"
echo ${SCRIPT_DIR}/setup_expt.py
OPTIONS=""
OPTIONS="${OPTIONS} --app ${APP} "
OPTIONS="${OPTIONS} --pslot ${PSLOT} "
OPTIONS="${OPTIONS} --idate ${IDATE} "
OPTIONS="${OPTIONS} --edate ${EDATE} "
OPTIONS="${OPTIONS} --resdet ${RESDET} "
OPTIONS="${OPTIONS} --cdump ${CDUMP} "
OPTIONS="${OPTIONS} --gfs_cyc ${GFS_CYC} "
OPTIONS="${OPTIONS} --comrot ${COMROT} "
OPTIONS="${OPTIONS} --expdir ${EXPDIR} "
OPTIONS="${OPTIONS} --icsdir ${ICSDIR} "
if [[ $RUN_TYPE == cycled ]]; then
OPTIONS="${OPTIONS} --resens ${RESENS} "
OPTIONS="${OPTIONS} --nens ${NENS} "
fi
if [[ $REPO == NeilBarton-NOAA ]]; then
OPTIONS="${OPTIONS} --suffix_pslot 'F' "
fi
${SCRIPT_DIR}/setup_expt.py ${RUN_TYPE} ${OPTIONS}
if [[ $? != 0 ]]; then
   echo 'setup_expt.py failed'
   exit 1
fi

fi
####################################
# link restart files to COMROT
if [[ $RUN_LINK_ICs == T ]]; then
  ${PWD}/LINK-ICs.sh ${IDATE} ${COMROT} ${APP} ${RESDET} ${RESENS} ${NENS} 
fi

####################################
# edit options for run
if [[ $RUN_EDIT_CONFIG == T ]]; then 

config_file=${EXPDIR}/config.base
echo " "
echo "Editing config.base file: $config_file"
sed -i 's/fv3-cpu/marine-cpu/g' ${config_file}
sed -i "s:${HOMEDIR}:${NPB_HOMEDIR}/${PSLOT}:g" ${config_file}
sed -i "s:${STMPDIR}:${NPB_HOMEDIR}/${PSLOT}:g" ${config_file}
sed -i 's:HPSS_PROJECT=emc-global:HPSS_PROJECT=emc-marine:g' ${config_file}
sed -i s:${EXPDIR}/'$PSLOT':${EXPDIR}:g ${config_file}
sed -i s:${COMROT}/'$PSLOT':${COMROT}:g ${config_file}
sed -i s:'$STMP'/RUNDIRS/'$PSLOT':$RUNDIR:g ${config_file}
sed -i s:'$NOSCRUB'/archive/'$PSLOT':'$NOSCRUB'/archive:g ${config_file}
sed -i s:'HPSSARCH="YES":HPSSARCH="NO"':g ${config_file}
[[ $RUN_TYPE == forecast-only ]] && sed -i 's:DOIAU="YES":DOIAU="NO":g' ${config_file}
[[ $ENKF == F ]] && sed -i s:'DOHYBVAR="YES":DOHYBVAR="NO"':g ${config_file}
[[ $IAU == F ]] && sed -i 's:DOIAU="YES":DOIAU="NO":g' ${config_file}
[[ $IAU == T ]] && sed -i 's/DOIAU=${DOIAU:-"NO"}/DOIAU=${DOIAU:-"YES"}/g' ${config_file}
if [[ ${APP:0:3} == S2S ]] && [[ $RUN_TYPE == cycled ]]; then
sed -i 's:imp_physics=8:imp_physics=11:g' ${config_file}
sed -i 's:CCPP_SUITE="FV3_GFS_v17_coupled_p8":CCPP_SUITE="FV3_GFS_v16_coupled":g' ${config_file}
fi

fi

##################################
# set up rocotoco xml file
if [[ $RUN_SETUP_XML == T ]]; then

echo " "
echo "setup workflow after changes config.base:"
${SCRIPT_DIR}/setup_xml.py $EXPDIR 
if [[ $? != 0 ]]; then
    echo 'setup_xml.py failed'
    exit 1
fi

fi

####################################
# validate xml file
if [[ $RUN_CRONTAB == T ]]; then

db_file=$EXPDIR/${PSLOT}.db
xml_file=$EXPDIR/${PSLOT}.xml
rocotorun -d $db_file -w $xml_file
if [[ $? != 0 ]]; then
    echo 'rocotorun failed, issues in xml file'
    exit 1
fi

####################################
# start crontab
echo " " 
echo "start crontab:" 
cron_file=$EXPDIR/$PSLOT.crontab
echo $cron_file
if [[ $MAIL == T ]]; then
    sed -i 's:MAILTO="":MAILTO="neil.barton@noaa.gov":g' $cron_file
fi
crontab -l | cat - $cron_file | crontab -

####################################
# echo crontab file
echo " "
echo "db=${db_file}"
echo "xml=${xml_file}"

fi
