#!/bin/sh
DTG=2012010100
CRES_HIRES=C384 #192
CRES_ENKF=C192
#CRES_ENKF=C384
LEVS=128
source ${PWD}/MACHINE-config.sh
TOPDIR=${NPB_WORKDIR}/CODE/UFS_UTILS/util/gdas_init
EXTRACT_DIR=${NPB_WORKDIR}/ICs/${DTG}/ORIG_RES
OUTDIR=${NPB_WORKDIR}/ICs/${DTG}

########################
# edit config file
cd $TOPDIR
git checkout config
config_file=${TOPDIR}/config
ORIG_EXTRACT_DIR=/lfs4/HFIP/emcda/'$USER'/stmp/gdas.init/input
ORIG_OUTDIR=/lfs4/HFIP/emcda/'$USER'/stmp/gdas.init/output
echo $config_file
sed -i 's/RUN_CHGRES=no/RUN_CHGRES=yes/g' ${config_file}
sed -i "s:yy=2021:yy=${year}:g" ${config_file}
sed -i "s:mm=03:mm=${month}:g" ${config_file}
sed -i "s:dd=21:dd=${day}:g" ${config_file}
sed -i "s:hh=06:hh=${hour}:g" ${config_file}
sed -i "s:${ORIG_EXTRACT_DIR}:${EXTRACT_DIR}:g" ${config_file}
sed -i "s:${ORIG_OUTDIR}:${OUTDIR}:g" ${config_file}
sed -i "s:CRES_HIRES=C192:CRES_HIRES=${CRES_HIRES}:g" ${config_file}
sed -i "s:CRES_ENKF=C96:CRES_ENKF=${CRES_ENKF}:g" ${config_file}
sed -i "s:LEVS=65:LEVS=${LEVS}:g" ${config_file}

########################
# run 
./driver.${m}.sh

########################
# change back config file
git checkout config

########################
echo 'DONE'

