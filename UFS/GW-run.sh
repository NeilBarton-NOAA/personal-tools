#!/bin/sh
set -u
####################################
# Run Script for seeting up global-worflow
#   https://global-workflow.readthedocs.io/en/latest/index.html
#
####################################
RUN_SETUP_EXPT=T && RUN_SETUP_XML=T && RUN_CRONTAB=T
REPO=NeilBarton-NOAA && HASH=EP5d_GEFS_ATMOS && PSLOT=ATMOSPERT
#REPO=NOAA-EMC && HASH=develop && PSLOT=DEV

####################################
IDATE=2017100400
APP=S2SWA #ATM #ATM, S2S, S2SW
RESENSATM=384
NENS=1

########################
# code location
CODE_DIR=${CODE_DIR:-${NPB_WORKDIR}/CODE/global-workflow_${HASH////\_}_${REPO}}
[[ ! -d ${CODE_DIR} ]] && echo "code is not at ${CODE_DIR}" &&  exit 1
#if [[ ! -d ${CODE_DIR} ]]; then
#    echo "code is not at ${CODE_DIR}"
#    exit 1
#fi

####################################
# User Defined Exp directories
EXPDIR=${NPB_WORKDIR}/RUNS/GW
COMROOT=${NPB_WORKDIR}/RUNS/GW/${PSLOT}/COMROOT 
CONFIGS_DIR=${EXPDIR}/${PSLOT}

####################################
# setup_expt.py script
if [[ $RUN_SETUP_EXPT == T ]]; then

echo 'RUNNING: setup_expt.py'
echo ${CODE_DIR}/workflow/setup_expt.py
[[ ${RUN_TYPE:-forecast-only} != cycled ]] && EDATE=${IDATE}
OPTIONS=""
OPTIONS="${OPTIONS} --idate ${IDATE} "
OPTIONS="${OPTIONS} --edate ${EDATE} "
OPTIONS="${OPTIONS} --app ${APP:-S2SWA} "
OPTIONS="${OPTIONS} --start ${START:-cold} "
OPTIONS="${OPTIONS} --gfs_cyc ${GFS_CYC:-1} "
OPTIONS="${OPTIONS} --resdetatmos ${RESDETATM:-384} "
OPTIONS="${OPTIONS} --resensatmos ${RESENSATM:-384} "
OPTIONS="${OPTIONS} --pslot ${PSLOT} "
OPTIONS="${OPTIONS} --expdir ${EXPDIR} "
OPTIONS="${OPTIONS} --comroot ${COMROOT} "
OPTIONS="${OPTIONS} --nens ${NENS:-0} "
OPTIONS="${OPTIONS} --yaml ${PWD}/YAMLS/gw_hera.yaml "

echo "${CODE_DIR}/workflow/setup_expt.py ${CDUMP:-gefs} ${RUN_TYPE:-forecast-only} ${OPTIONS}"
${CODE_DIR}/workflow/setup_expt.py ${CDUMP:-gefs} ${RUN_TYPE:-forecast-only} ${OPTIONS}
if [[ $? != 0 ]]; then
   echo 'setup_expt.py failed'
   exit 1
fi

source $PWD/MACHINE-config.sh
config_file=${CODE_DIR}/parm/config/${CDUMP:-gefs}/config.base
sed -i "s:${COMROOT}/"'${PSLOT}'":${COMROOT}:g" ${config_file}
#sed -i "s:${HOMEDIR}:${COMROOT}/GLOBAL:g" ${config_file}

fi

##################################
# set up rocotoco xml file
if [[ $RUN_SETUP_XML == T ]]; then
ln -s ${CODE_DIR}/workflow/setup_xml.py ${EXPDIR}/${PSLOT}
ln -s ${CODE_DIR}/workflow/rocoto_viewer.py ${EXPDIR}/${PSLOT}

echo " "
echo "RUNNING: setup_xml.py after changes config.base:"
echo "${CODE_DIR}/workflow/setup_xml.py ${EXPDIR}/${PSLOT}"
${CODE_DIR}/workflow/setup_xml.py ${EXPDIR}/${PSLOT} --maxtries 1
if [[ $? != 0 ]]; then
    echo 'setup_xml.py failed'
    exit 1
fi

fi

####################################
# validate xml file
if [[ ${RUN_CRONTAB} == T ]]; then

set +u
source ${EXPDIR}/${PSLOT}/config.base
cd ${EXPDIR}
ln -s ${RUNDIR} RUNDIR
ln -s ${COMROOT}/logs/${IDATE} LOGS_COMROOT
ln -s ${CODE_DIR} CODE
ln -s ${CODE_DIR}/parm/config/${CDUMP:-gefs} ORIG_CONFIGS
#ln -s ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
rm -r ${COMROOT}/${PSLOT}

set -u
xml_file=${EXPDIR}/${PSLOT}/${PSLOT}.xml
db_file=${xml_file:0:-3}db 
cron_file=${xml_file:0:-3}crontab
rocotorun -d ${db_file} -w ${xml_file}
if [[ $? != 0 ]]; then
    echo 'rocotorun failed, issues in xml file'
    exit 1
fi

####################################
# start crontab
echo " " 
echo "STARTING CRONTAB:" 
echo ${cron_file}
crontab -l | cat - ${cron_file} | crontab -

####################################
# echo crontab file
echo "db=${db_file}"
echo "xml=${xml_file}"

fi
