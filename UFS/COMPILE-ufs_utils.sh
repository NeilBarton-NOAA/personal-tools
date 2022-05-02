#!/bin/sh
source $PWD/MACHINE-config.sh
TOPDIR=$WORKDIR
cd $TOPDIR
machine=$(uname -n)
code=UFS_UTILS
########################
# check out code
cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone --recursive https://github.com/NOAA-EMC/UFS_UTILS.git ${code}
fi

########################
# build model
cd ${TOPDIR}/${code}
sh build_all.sh -c
cd fix
sh link_fixdirs.sh emc ${m} 
echo 'DONE'

