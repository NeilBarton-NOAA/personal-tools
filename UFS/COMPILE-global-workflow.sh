#!/bin/sh
source $PWD/MACHINE-config.sh
TOPDIR=$WORKDIR
cd $TOPDIR
machine=$(uname -n)
branch=pre_p8b
code=global-workflow_${branch}

########################
# check out code
cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone https://github.com/NOAA-EMC/global-workflow.git ${code}
    cd ${code}
    git checkout $branch
else
    cd ${code}
fi

########################
# build model
cd ${TOPDIR}/${code}/sorc
sh checkout.sh
sh build_all.sh -c
sh link_workflow.sh emc ${m} coupled
echo 'DONE'
