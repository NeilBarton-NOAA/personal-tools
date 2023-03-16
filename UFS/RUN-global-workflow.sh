#!/bin/sh
####################################
# Run Script for seeting up global-worflow
#   https://global-workflow.readthedocs.io/en/latest/index.html
#
####################################
set -u
source $PWD/MACHINE-config.sh

####################################
#REPO=NOAA-EMC && HASH=prototype/hr1 && PSLOT=HR1 
REPO=NOAA-EMC && HASH=develop && PSLOT=DEV
IDATE=2019120300
EDATE=$( $PWD/DTG-add-time.sh $IDATE 1 ) 
RUN_TYPE=forecast-only
CDUMP=gfs
APP=S2SW #ATM #ATM, S2S, S2SW
#NENS=20
ICSDIR=${NPB_WORKDIR}/ICs/${IDATE}

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
NENS=${NENS:-0} 
GFS_CYC=${GFS_CYC:-1}
ENKF=${ENKF:-T}
IAU=${IAU:-T}
HPSSARCH=${HPSSARCH:-T}
HASH=${HASH:-develop}
CODE_DIR=${CODE_DIR:-${NPB_WORKDIR}/CODE/global-workflow_${HASH////\_}_${REPO}}
SCRIPT_DIR=${CODE_DIR}/workflow

CDUMP=${CDUMP:-gdas} 
RUN_TYPE=${RUN_TYPE:-cycled}
[[ ${ENKF} == F ]] && NENS=0
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
EXPDIR=${NPB_WORKDIR}/RUNS
COMROT=${NPB_WORKDIR}/RUNS/${PSLOT}/COMROT 
CONFIGS_DIR=${EXPDIR}/${PSLOT}
MAIL=F

####################################
# check for code
if [[ ! -d $CODE_DIR ]]; then
    echo "code is not at $CODE_DIR"
    exit 1
fi

####################################
# link restart files to COMROT
if [[ $RUN_LINK_ICs == T ]]; then
  source ${PWD}/LINK-ICs.sh ${IDATE} ${COMROT} ${APP} ${CDUMP} 
  if (( $? > 0 )); then
    echo 'LINK-ICs.sh failed'
    exit 1
  fi
fi

####################################
# setup_expt.py script
if [[ $RUN_SETUP_EXPT == T ]]; then

echo 'RUNNING: setup_expt.py'
echo ${SCRIPT_DIR}/setup_expt.py
OPTIONS=""
OPTIONS="${OPTIONS} --app ${APP} "
OPTIONS="${OPTIONS} --pslot ${PSLOT} "
OPTIONS="${OPTIONS} --idate ${IDATE} "
OPTIONS="${OPTIONS} --edate ${EDATE} "
OPTIONS="${OPTIONS} --resdet ${RESDET} "
OPTIONS="${OPTIONS} --cdump ${CDUMP} "
OPTIONS="${OPTIONS} --gfs_cyc ${GFS_CYC} "
OPTIONS="${OPTIONS} --expdir ${EXPDIR} "
OPTIONS="${OPTIONS} --comrot ${COMROT} "
OPTIONS="${OPTIONS} --start ${START} "
#if [[ $RUN_LINK_ICs == F ]]; then
#OPTIONS="${OPTIONS} --icsdir ${ICSDIR} "
#fi
if [[ $RUN_TYPE != forecast-only ]]; then
OPTIONS="${OPTIONS} --resens ${RESENS} "
OPTIONS="${OPTIONS} --nens ${NENS} "
OPTIONS="${OPTIONS} --start ${START} "
fi
${SCRIPT_DIR}/setup_expt.py ${RUN_TYPE} ${OPTIONS}
if [[ $? != 0 ]]; then
   echo 'setup_expt.py failed'
   exit 1
fi

fi

####################################
# link ICs again in case removed
if [[ $RUN_LINK_ICs == T ]]; then
  ${PWD}/LINK-ICs.sh ${IDATE} ${COMROT} ${APP} ${CDUMP} 
  if (( $? > 0 )); then
    echo 'LINK-ICs.sh failed'
    exit 1
  fi
fi
####################################
# edit options for run
if [[ $RUN_EDIT_CONFIG == T ]]; then 

config_file=${CONFIGS_DIR}/config.base
echo " "
echo "EDITING: $config_file"
sed -i 's/fv3-cpu/marine-cpu/g' ${config_file}
sed -i 's:HPSS_PROJECT=emc-global:HPSS_PROJECT=emc-marine:g' ${config_file}
sed -i "s:${HOMEDIR}:${COMROT}/GLOBAL:g" ${config_file}
sed -i "s:${COMROT}/"'${PSLOT}'":${COMROT}:g" ${config_file}
sed -i 's:KEEPDATA="NO":KEEPDATA="YES":g' ${config_file}
[[ $HPSSARCH == F ]] && sed -i s:'HPSSARCH="YES":HPSSARCH="NO"':g ${config_file}
[[ $ENKF == F ]] && sed -i s:'DOHYBVAR="YES":DOHYBVAR="NO"':g ${config_file}
[[ $IAU == F ]] && sed -i 's:DOIAU="YES":DOIAU="NO":g' ${config_file}
#if [[ ${APP:0:3} == S2S ]] && [[ $RUN_TYPE == cycled ]]; then
#sed -i 's:imp_physics=8:imp_physics=11:g' ${config_file}
#sed -i 's:CCPP_SUITE="FV3_GFS_v17_coupled_p8":CCPP_SUITE="FV3_GFS_v16_coupled":g' ${config_file}
#fi
#sed -i 's:imp_physics=8:imp_physics=11:g' ${config_file}

fi

##################################
# set up rocotoco xml file
if [[ $RUN_SETUP_XML == T ]]; then

echo " "
echo "RUNNING: setup_xml.py after changes config.base:"
echo "${SCRIPT_DIR}/setup_xml.py $CONFIGS_DIR"
${SCRIPT_DIR}/setup_xml.py $CONFIGS_DIR
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
