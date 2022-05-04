#!/bin/sh
year=2020
month=03
day=31
hour=00
source ${PWD}/MACHINE-config.sh
TOPDIR=${NPB_WORKDIR}/CODE/UFS_UTILS/util/gdas_init
EXTRACT_DIR=${NPB_WORKDIR}/ICs/${year}${month}${day}${hour}/ORIG_RES
OUTDIR=${NPB_WORKDIR}/ICs/${year}${month}${day}${hour}
cd $TOPDIR

########################
# edit config file
config_file=${TOPDIR}/config
ORIG_EXTRACT_DIR=/lfs4/HFIP/emcda/$USER/stmp/gdas.init/input
ORIG_OUTDIR=/lfs4/HFIP/emcda/$USER/stmp/gdas.init/output
echo $config_file
sed -i 's/RUN_CHGRES=no/RUN_CHGRES=yes/g' ${config_file}
sed -i "s:yy=2021:yy=${year}:g" ${config_file}
sed -i "s:mm=03:mm=${month}:g" ${config_file}
sed -i "s:dd=21:dd=${day}:g" ${config_file}
sed -i "s:hh=06:hh=${hour}:g" ${config_file}
sed -i "${ORIG_EXTRACT_DIR}:${EXTRACT_DIR}:g" ${config_file}
sed -i "${ORIG_OUTDIR}:${OUTDIR}:g" ${config_file}

########################
# run 
./driver.${m}.sh

########################
# change back config file
git checkout config

########################
echo 'DONE'

