#!/bin/sh 
set -u
########################
# Code to Checkout/Compile
#REPO=NeilBarton-NOAA && HASH=GEFS_REFORECASTING
REPO=NeilBarton-NOAA &&  HASH=EP5d_GEFS_ATMOS 
#REPO=NOAA-EMC && HASH=develop
COMPILE=T

########################
# check out code
code=global-workflow_${HASH////\_}_${REPO}
TOPDIR=${NPB_WORKDIR}/CODE
mkdir -p ${TOPDIR} && cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone --recursive https://github.com/${REPO}/global-workflow.git ${code}
    cd ${code}
    git checkout --recurse-submodules ${HASH}
else
    cd ${code}
    git pull
    git submodule update --recursive
fi

########################
# build model
if [[ ${COMPILE} == T ]]; then
cd ${TOPDIR}/${code}/sorc
cat <<EOF > setup_all_ufs.sh
#!/bin/sh
sh build_all.sh -gu 
sh link_workflow.sh  
EOF
chmod 755 setup_all_ufs.sh
echo "compiling in ${TOPDIR}/${code}/sorc"
log_file=gw_${HASH////\_}_${REPO}_compile.log
nohup ./setup_all_ufs.sh > ${log_file} 2>&1 &
tail -f ${log_file}
fi
