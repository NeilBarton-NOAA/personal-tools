#!/bin/sh
source $PWD/MACHINE-config.sh
TOPDIR=$WORKDIR
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
cd ${TOPDIR}/global-workflow/sorc
sh checkout.sh
sh build_all.sh -c
sh link_workflow.sh emc ${m} coupled
echo 'DONE'
