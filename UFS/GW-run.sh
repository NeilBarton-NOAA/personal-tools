#!/bin/sh
####################################
# Run Script for seeting up global-worflow
#   https://global-workflow.readthedocs.io/en/latest/index.html
#
####################################
set -u
source $PWD/MACHINE-config.sh

####################################
REPO=NeilBarton-NOAA && HASH=GEFS && PSLOT=GEFS_TEST
#REPO=NOAA-EMC && HASH=develop && PSLOT=DEV
IDATE=2021032312
EDATE=$( $PWD/DTG-add-time.sh $IDATE 1 ) 
RUN_TYPE=forecast-only #cycled
CDUMP=gefs
APP=S2SWA #W #ATM #ATM, S2S, S2SW
RESDETATM=384
RESENSATM=384
RESDETOCN=025
NENS=2
GFS_CYC=4
#ICSDIR=${NPB_WORKDIR}/ICs/${IDATE}
START=warm

####################################
# Sub-Components of script
RUN_SETUP_EXPT=T
RUN_LINK_ICs=F
RUN_EDIT_CONFIG=T
RUN_SETUP_XML=T
RUN_CRONTAB=T

########################
# defaults
APP=${APP:-S2SW} 
RESDET=${RESDET:-384} 
RESENS=${RESENS:-96} 
REPO=${REPO:-NeilBarton-NOAA}
NENS=${NENS:-0} 
GFS_CYC=${GFS_CYC:-1}
IAU=${IAU:-F}
HPSSARCH=${HPSSARCH:-F}
HASH=${HASH:-develop}
CODE_DIR=${CODE_DIR:-${NPB_WORKDIR}/CODE/global-workflow_${HASH////\_}_${REPO}}
SCRIPT_DIR=${CODE_DIR}/workflow

CDUMP=${CDUMP:-gfs} 
RUN_TYPE=${RUN_TYPE:-cycled}
# options depending on configuration
if [[ ${RUN_TYPE} == cycled ]]; then
    PSLOT=${PSLOT:-${APP}_IAU-${IAU}_${START}_${RESDET}_${IDATE}}
else
    PSLOT=${PSLOT:-${APP}_${IDATE}}
fi
[[ $RUN_TYPE != cycled ]] && EDATE=${IDATE}

####################################
# personalized options
ICSDIR=${ICSDIR:-${NPB_WORKDIR}/ICs}
EXPDIR=${NPB_WORKDIR}/RUNS/GW
COMROOT=${NPB_WORKDIR}/RUNS/GW/${PSLOT}/COMROOT 
CONFIGS_DIR=${EXPDIR}/${PSLOT}
MAIL=F

####################################
# check for code
if [[ ! -d $CODE_DIR ]]; then
    echo "code is not at $CODE_DIR"
    exit 1
fi

####################################
# link restart files to COMROOT
#if [[ $RUN_LINK_ICs == T ]]; then
#  source ${PWD}/LINK-ICs.sh ${IDATE} ${COMROOT} ${APP} ${CDUMP} ${NENS} 
#  if (( $? > 0 )); then
#    echo 'LINK-ICs.sh failed'
#    exit 1
#  fi
#fi

####################################
# setup_expt.py script
if [[ $RUN_SETUP_EXPT == T ]]; then

echo 'RUNNING: setup_expt.py'
echo ${SCRIPT_DIR}/setup_expt.py
OPTIONS=""
OPTIONS="${OPTIONS} --idate ${IDATE} "
OPTIONS="${OPTIONS} --edate ${EDATE} "
OPTIONS="${OPTIONS} --app ${APP} "
OPTIONS="${OPTIONS} --start ${START} "
OPTIONS="${OPTIONS} --gfs_cyc ${GFS_CYC} "
OPTIONS="${OPTIONS} --resdetatmos ${RESDETATM} "
OPTIONS="${OPTIONS} --resensatmos ${RESENSATM} "
OPTIONS="${OPTIONS} --resdetocean ${RESDETOCN} "
OPTIONS="${OPTIONS} --pslot ${PSLOT} "
OPTIONS="${OPTIONS} --expdir ${EXPDIR} "
OPTIONS="${OPTIONS} --comroot ${COMROOT} "
OPTIONS="${OPTIONS} --nens ${NENS} "
if [[ $RUN_TYPE != forecast-only ]]; then
OPTIONS="${OPTIONS} --start ${START} "
fi
OPTIONS="${OPTIONS} --o "
echo "${SCRIPT_DIR}/setup_expt.py ${CDUMP} ${RUN_TYPE} ${OPTIONS}"
${SCRIPT_DIR}/setup_expt.py ${CDUMP} ${RUN_TYPE} ${OPTIONS}
if [[ $? != 0 ]]; then
   echo 'setup_expt.py failed'
   exit 1
fi
ln -sf ${CODE_DIR}/parm/config/${CDUMP}/* ${CONFIGS_DIR}

fi

####################################
# link ICs 
if [[ $RUN_LINK_ICs == T ]]; then
  ${PWD}/LINK-ICs.sh ${IDATE} ${COMROOT} ${APP} ${CDUMP} ${NENS} 
  if (( $? > 0 )); then
    echo 'LINK-ICs.sh failed'
    exit 1
  fi
fi

####################################
# edit options for run
config_file=${CONFIGS_DIR}/config.base
if [[ $RUN_EDIT_CONFIG == T ]]; then 

echo " "
echo "EDITING: $config_file"
sed -i 's/fv3-cpu/marine-cpu/g' ${config_file}
sed -i 's:HPSS_PROJECT=emc-global:HPSS_PROJECT=emc-marine:g' ${config_file}
sed -i "s:${HOMEDIR}:${COMROOT}/GLOBAL:g" ${config_file}
sed -i "s:${COMROOT}/"'${PSLOT}'":${COMROOT}:g" ${config_file}
sed -i 's:KEEPDATA="NO":KEEPDATA="YES":g' ${config_file}
[[ $HPSSARCH == F ]] && sed -i s:'HPSSARCH="YES":HPSSARCH="NO"':g ${config_file}
#[[ $ENKF == F ]] && sed -i s:'DOHYBVAR="YES":DOHYBVAR="NO"':g ${config_file}
#[[ $IAU == F ]] && sed -i 's:DOIAU="YES":DOIAU="NO":g' ${config_file}

fi

##################################
# set up rocotoco xml file
if [[ $RUN_SETUP_XML == T ]]; then
ln -s ${SCRIPT_DIR}/setup_xml.py ${CONFIGS_DIR}
ln -s ${SCRIPT_DIR}/rocoto_viewer.py ${CONFIGS_DIR}

echo " "
echo "RUNNING: setup_xml.py after changes config.base:"
echo "${SCRIPT_DIR}/setup_xml.py ${CONFIGS_DIR}"
${SCRIPT_DIR}/setup_xml.py ${CONFIGS_DIR}
if [[ $? != 0 ]]; then
    echo 'setup_xml.py failed'
    exit 1
fi

fi

####################################
# validate xml file
if [[ ${RUN_CRONTAB} == T ]]; then

set +u
source ${config_file}
cd ${EXPDIR}
ln -s ${RUNDIR} RUNDIR
ln -s ${COMROOT}/logs LOGS_COMROOT
rm -r ${COMROOT}/${PSLOT}

set -u
xml_file=$(ls $CONFIGS_DIR/*.xml)
db_file=${xml_file:0:-3}db 
cron_file=${xml_file:0:-3}crontab
rocotorun -d $db_file -w $xml_file
if [[ $? != 0 ]]; then
    echo 'rocotorun failed, issues in xml file'
    exit 1
fi

####################################
# start crontab
echo " " 
echo "STARTING CRONTAB:" 
echo $cron_file
if [[ $MAIL == T ]]; then
    sed -i 's:MAILTO="":MAILTO="neil.barton@noaa.gov":g' $cron_file
fi
crontab -l | cat - $cron_file | crontab -

####################################
# echo crontab file
echo "db=${db_file}"
echo "xml=${xml_file}"

fi
