#!/bin/sh
set -u
source ${PWD}/MACHINE-config.sh
TOPDIR=${NPB_WORKDIR}/CODE
mkdir -p ${TOPDIR}
cd ${TOPDIR}

#REPO=NeilBarton-NOAA && HASH=GEFS
REPO=rmontuoro && HASH=gefs/ep4a
COMPILE=T
code=global-workflow_${HASH////\_}_${REPO}

########################
# check out code
cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone https://github.com/${REPO}/global-workflow.git ${code}
    cd ${code}
    git checkout ${HASH}
else
    cd ${code}
    git pull
fi

########################
# build model
if [[ ${COMPILE} == T ]]; then
#sh checkout.sh -g # g gsi u for GDASApp
cd ${TOPDIR}/${code}/sorc
cat <<EOF > setup_all_ufs.sh
#!/bin/sh
sh checkout.sh 
sh build_all.sh 
sh link_workflow.sh  
EOF
chmod 755 setup_all_ufs.sh
echo "compiling in ${TOPDIR}/${code}/sorc"
code=global-workflow_${HASH////\_}_${REPO}
nohup ./setup_all_ufs.sh ${PWD}/gw_${HASH////\_}_compile.log &
fi
