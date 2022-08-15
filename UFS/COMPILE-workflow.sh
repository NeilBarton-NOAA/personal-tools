#!/bin/sh
set -u
source $PWD/MACHINE-config.sh
TOPDIR=$NPB_WORKDIR/CODE
mkdir -p $TOPDIR
cd $TOPDIR

REPO=NeilBarton-NOAA 
#REPO=NOAA-EMC
#REPO=XianwuXue-NOAA

branch=develop 
#branch=pre_p8b
#branch=S2SW_atmosDA
#branch=S2SW_atmosDA_dev
#branch=feature/ges_v13_coupled_post

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
fi

########################
# build model
cd ${TOPDIR}/${code}/sorc
cat <<EOF > setup_all_ufs.sh
#!/bin/sh
sh checkout.sh #-g
sh build_all.sh #-c #not needed for current develop
sh link_workflow.sh emc ${m} 
EOF
chmod 755 setup_all_ufs.sh
echo "compiling in ${TOPDIR}/${code}/sorc"
nohup ./setup_all_ufs.sh &

