#!/bin/sh
year=2020
month=03
day=31
hour=00

source $PWD/MACHINE-config.sh
TOPDIR=$WORKDIR/CODE/UFS_UTILS/util/gdas_init
cd $TOPDIR

########################
# edit config file
config_file=${TOPDIR}/config
sed -i 's/RUN_CHGRES=no/RUN_chgres=yes/g' ${config_file}
sed -i "s:yy=2021:yy=${year}:g" ${config_file}
sed -i "s:mm=03:mm=${month}:g" ${config_file}
sed -i "s:dd=21:dd=${day}:g" ${config_file}
sed -i "s:hh=06:hh=${hour}:g" ${config_file}

########################
# run 
./driver.${m}.sh

########################
# change back config file
git checkout config
#sed -i 's/RUN_CHGRES=yes/RUN_chgres=no/g' ${config_file}
#sed -i "s:yy=${year}:yy=2021:g" ${config_file}
#sed -i "s:mm=${month}:mm=03:g" ${config_file}
#sed -i "s:mm=${day}:dd=21:g" ${config_file}
#sed -i "s:hh=${hour}:hh=06:g" ${config_file}
########################
echo 'DONE'

