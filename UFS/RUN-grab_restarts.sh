#!/bin/sh
set -u
DTG=2020040100
#DTG=2018030100
#DTG=2021032200
CRES_HIRES=C384 #192
#CRES_HIRES=C96 #192
#CRES_ENKF=C192
CRES_ENKF=C96
LEVS=128
USE_V16RETRO=T
source ${PWD}/MACHINE-config.sh
TOPDIR=${NPB_WORKDIR}/CODE/UFS_UTILS_NeilBarton-NOAA/util/gdas_init
EXTRACT_DIR=${NPB_WORKDIR}/ICs/${DTG}/ORIG_RES
OUTDIR=${NPB_WORKDIR}/ICs/${DTG}

########################
# edit config file
cd $TOPDIR
git checkout config
config_file=${TOPDIR}/config
ORIG_EXTRACT_DIR=/lfs/h2/emc/stmp/'$USER'/gdas.init/input
ORIG_OUTDIR=/lfs/h2/emc/stmp/'$USER'/gdas.init/output
year=${DTG:0:4}
month=${DTG:4:2}
day=${DTG:6:2}
hour=${DTG:8:2}
echo $config_file
sed -i 's/RUN_CHGRES=no/RUN_CHGRES=yes/g' ${config_file}
sed -i 's/EXTRACT_DATA=no/EXTRACT_DATA=yes/g' ${config_file}
sed -i "s:yy=2022:yy=${year}:g" ${config_file}
sed -i "s:mm=05:mm=${month}:g" ${config_file}
sed -i "s:dd=06:dd=${day}:g" ${config_file}
sed -i "s:hh=06:hh=${hour}:g" ${config_file}
sed -i "s:${ORIG_EXTRACT_DIR}:${EXTRACT_DIR}:g" ${config_file}
sed -i "s:${ORIG_OUTDIR}:${OUTDIR}:g" ${config_file}
sed -i "s:CRES_HIRES=C192:CRES_HIRES=${CRES_HIRES}:g" ${config_file}
sed -i "s:CRES_ENKF=C96:CRES_ENKF=${CRES_ENKF}:g" ${config_file}
sed -i "s:LEVS=128:LEVS=${LEVS}:g" ${config_file}
if [[ $USE_V16RETRO == F ]]; then
    sed -i "s:use_v16retro=yes:use_v16retro=no:g" ${config_file}
fi

########################
# remove logs
rm -f ${TOPDIR}/log.*

########################
# run 
./driver.${m}.sh

########################
echo "LOG FILES AT: ${TOPDIR}"
echo "SUBMITTED: ${DTG}"

