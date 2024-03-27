#!/bin/sh
set -u
REPO=NeilBarton-NOAA && HASH=EP5d_GEFS_ATMOS 
CI_TEST=C96C48_hybatmDA

HOMEgfs=${NPB_WORKDIR}/CODE/global-workflow_${HASH////\_}_${REPO}
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1

export RUNTESTS=${NPB_WORKDIR}/RUNS/CI 
export pslot="${CI_TEST}"
export pslot="TEST"
source ${HOMEgfs}/ci/platforms/config.hera
cd ${HOMEgfs}
${HOMEgfs}/workflow/create_experiment.py --yaml "${HOMEgfs}/ci/cases/pr/${CI_TEST}.yaml" 

################################################
# RocotoRun and add to crontab
xml_file=${RUNTESTS}/EXPDIR/${pslot}/${pslot}.xml
db_file=${xml_file:0:-3}db 
cron_file=${xml_file:0:-3}crontab
rocotorun -d ${db_file} -w ${xml_file}
if [[ $? != 0 ]]; then
    echo 'rocotorun failed, issues in xml file'
    exit 1
fi
# start crontab
echo " " 
echo "STARTING CRONTAB:" 
echo ${cron_file}
crontab -l | cat - ${cron_file} | crontab -
# echo crontab file
echo "db=${db_file}"
echo "xml=${xml_file}"


