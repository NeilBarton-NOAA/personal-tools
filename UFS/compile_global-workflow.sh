#!/bin/sh

TOPDIR=/work/noaa/marine/nbarton
cd $TOPDIR
machine=$(uname -n)
code=global-workflow

########################
# check out code
cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone https://github.com/NOAA-EMC/global-workflow.git
    cd ${code}
else
    cd ${code}
fi

########################
# build model
if [[ ${machine} == *Orion* ]]; then
    m=orion
fi
sh checkout.sh
sh build_all.sh -c
sh link_workflow.emc ${m} coupled
echo 'DONE'
