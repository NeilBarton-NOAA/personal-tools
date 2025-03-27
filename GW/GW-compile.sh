#!/bin/sh 
set -u
set -x
# https://global-workflow.readthedocs.io/en/latest/
########################
# Code to Checkout/Compile
REPO=NOAA-EMC && HASH=develop
REPO=NeilBarton-NOAA && HASH=SFS_baseline_rocotofix
#REPO=EricSinsky-NOAA && HASH=feature/update_reforecast
GEFS=F && SFS=T && GFS=F
COMPILE=T

########################
# check out code
code=gw_${HASH////\_}_${REPO}
if [[ ${GFS} == T ]]; then
    code=${code}_GFS
fi
TOPDIR=${NPB_WORKDIR}/CODE
mkdir -p ${TOPDIR} && cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone --recursive https://github.com/${REPO}/global-workflow.git ${code}
    cd ${code}
    git checkout ${HASH}
    git checkout --recurse-submodules ${HASH}
#else
#    cd ${code}
#    git submodule update --recursive --remote
#    git pull
fi

########################
# build model
if [[ ${COMPILE} == T ]]; then
OPTIONS=""
#[[ ${GEFS} == T ]] && OPTIONS="${OPTIONS} gefs"
#[[ ${SFS} == T ]] && OPTIONS="${OPTIONS} sfs"
#[[ ${GFS} == T ]] && OPTIONS="${OPTIONS} gfs"

# Old Compile Options
[[ ${GEFS} == T ]] && OPTIONS="-gw -j 8"
[[ ${SFS} == T ]] && OPTIONS="-w -y -j 8"
[[ ${GFS} == T ]] && OPTIONS="-w -y -j 8"

cd ${TOPDIR}/${code}/sorc
cat <<EOF > setup_all_ufs.sh
#!/bin/sh
sh build_all.sh ${OPTIONS}
sh link_workflow.sh  
EOF
chmod 755 setup_all_ufs.sh
echo "compiling in ${TOPDIR}/${code}/sorc"
log_file=gw_${HASH////\_}_${REPO}_compile.log
nohup ./setup_all_ufs.sh > ${log_file} 2>&1 &
tail -f ${log_file}
fi
