#!/bin/sh
set -u
source $PWD/MACHINE-config.sh
TOPDIR=$NPB_WORKDIR/CODE
mkdir -p $TOPDIR
cd $TOPDIR

#REPO=NeilBarton-NOAA 
#branch=S2S_cycle
REPO=NOAA-EMC
branch=develop 

code=global-workflow_${branch////\_}_${REPO}
########################
# check out code
cd ${TOPDIR}
if [[ ! -d ${code} ]]; then
    git clone https://github.com/${REPO}/global-workflow.git ${code}
    cd ${code}
    git checkout $branch
else
    cd ${code}
    git pull
fi

########################
# build model
cd ${TOPDIR}/${code}/sorc
cat <<EOF > setup_all_ufs.sh
#!/bin/sh
sh checkout.sh -g
sh build_all.sh 
sh link_workflow.sh  
EOF
chmod 755 setup_all_ufs.sh
echo "compiling in ${TOPDIR}/${code}/sorc"
nohup ./setup_all_ufs.sh &

