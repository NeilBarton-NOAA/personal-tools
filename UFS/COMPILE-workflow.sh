#!/bin/sh
source $PWD/MACHINE-config.sh
TOPDIR=$NPB_WORKDIR/CODE
mkdir -p $TOPDIR
cd $TOPDIR
machine=$(uname -n)
REPO=NeilBarton-NOAA 
#REPO=NOAA-EMC
#branch=develop 
#branch=pre_p8b
branch=S2SW_atmosDA
code=global-workflow_${branch}_${REPO}_ATM
########################
# check out code
cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone https://github.com/${REPO}/global-workflow.git ${code}
    cd ${code}
    git checkout $branch
else
    cd ${code}
fi

########################
# build model
cd ${TOPDIR}/${code}/sorc
sh checkout.sh
sh build_all.sh #-c #not needed for current develop
sh link_workflow.sh emc ${m} coupled
echo 'DONE'
