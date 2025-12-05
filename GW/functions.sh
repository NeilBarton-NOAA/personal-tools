#!/bin/sh
set -u
################################################
# Machine Specific and Personalized options
machine_config() {
export RUNTESTS=${NPB_WORKDIR}/RUNS #/gw_${HASH////\_}_${REPO}
TOPICDIR=${NPB_WORKDIR}/ICs
machine=$(uname -n)
case ${machine} in
*Orion*)     m=orion ;    
             TOPICDIR=/work/noaa/marine/Yangxing.Zheng/ICs ;;
hercules*)   m=hercules ; 
             TOPICDIR=/work/noaa/marine/Yangxing.Zheng/ICs ;;
gaea*)       m=gaeac6 ;   
             TOPICDIR=/gpfs/f6/sfs-emc/proj-shared/Yangxing.Zheng/SFS/ICs ;;
             #TOPICDIR=${NPB_WORKDIR}/ICs ;; 
u*)          m=ursa ;     
             TOPICDIR=/scratch4/NCEPDEV/global/Yangxing.Zheng/ICs ;;
*[cd]login*) m=wcoss2 ;;
esac
export TOPICDIR=${TOPICDIR}
}

################################################
# Machine Specific and Personalized options
get_yamls() {
DEFAULT_YAMLS=${1}
CI_FORECAST=${2:-F}
CI_DA=${3:-F}
[[ -z "${YAML+x}" ]] && YAML=()
if [[ ${DEFAULT_YAMLS} == T ]]; then
    for f in $( find ${PWD}/YAMLS -name C*.yaml ); do YAML+=("${f}"); done
fi
if [[ ${CI_FORECAST} == T ]]; then
    for f in $( find ${HOMEgfs}/dev/ci/cases/pr -name *.yaml | xargs grep -l --exclude="*ecflow*" forecast-only | xargs grep -L ${machine} ); do YAML+=("$f"); done
fi 
if [[ ${CI_DA} == T ]]; then
    for f in $( find ${HOMEgfs}/dev/ci/cases/pr -name *.yaml | xargs grep -l --exclude="*ecflow*" cycled | xargs grep -L ${machine} ); do YAML+=("$f"); done
fi 
export YAML
}

################################################
# Clone gw if needed
clone_gw () {
HOMEgfs=${1}
HASH=${2}
REPO=${3}
if [[ ! -d ${HOMEgfs} ]]; then
    ORDIR=${PWD}
    TOPDIR=${HOMEgfs}/../
    mkdir -p ${TOPDIR} && cd ${TOPDIR}
    git clone --recursive -b ${HASH} git@github.com:${REPO}/global-workflow.git $(basename ${HOMEgfs})
    [[ $? > 0 ]] && exit 1
    cd ${ORDIR}
fi
}

################################################
# Build only gw options that are needed 
build_gw () {
HOMEgfs=${1}
ACCOUNT=${2}
YAMLS=${@:3}
# See of the link_workflow.sh script needs to run
cd ${HOMEgfs}/sorc
[[ ! -L ${HOMEgfs}/fix/mom6 ]] && sh link_workflow.sh
# Check what options need to be compiled
OPTIONS=()
for f in ${YAMLS}; do
    net=$( grep net ${f} | awk '{print $2}' )
    found=F
    for OPTION in ${OPTIONS[@]}; do
        [[ ${OPTION} == ${net} ]] && found=T && break 
    done
    [[ "${found}" == "F" ]] && [[ ! -f ${HOMEgfs}/exec/${net}_model.x ]] && OPTIONS+=("${net}")
done 
if [[ ${#OPTIONS[@]} -gt 0 ]]; then
    echo "Building: ${OPTIONS[@]}"
    sh build_compute.sh -A ${ACCOUNT} ${OPTIONS[@]} >& ~/GW/build_$(basename ${HOMEgfs}).log &
fi
}

################################################
# Run create_experiment script 
create_experiment () {
HOMEgfs=${1}
machine=${2}
export HPC_ACCOUNT=${3}
YAMLS=${@:4}
local YAML
source ${HOMEgfs}/dev/ci/platforms/config.${machine/.*}
source ${HOMEgfs}/dev/ush/gw_setup.sh >& /dev/null
export HPC_ACCOUNT=${COMPUTE_ACCOUNT}
for YAML in ${YAMLS}; do
    echo "create_experiment.py: ${YAML}"
    export pslot=$(basename ${YAML/.yaml*})_$(basename ${HOMEgfs})
    ${HOMEgfs}/dev/workflow/create_experiment.py --yaml "${YAML}"
    eval "$(PDY=0 cyc=0 source "${RUNTESTS}/EXPDIR/${pslot}/config.base" >& /dev/null; echo DATAROOT="${STMP}/RUNDIRS/${PSLOT}")"
    [[ -d ${DATAROOT} ]] && echo "Removing ${DATAROOT}" && rm -r ${DATAROOT}
done
}

################################################
# link items to EXPDIR for personal debugging 
link_EXPDIR () {
HOMEgfs=${1}
YAMLS=${@:2}
local YAML
ln -sf ${RUNTESTS}/EXPDIR ${PWD}/GW 
for YAML in ${YAMLS}; do
    pslot=$(basename ${YAML/.yaml*})_$(basename ${HOMEgfs})
    EXPDIR=${RUNTESTS}/EXPDIR/${pslot}
    COMROOT=${RUNTESTS}/COMROOT/${pslot}
    eval "$(PDY=0 cyc=0 source "${RUNTESTS}/EXPDIR/${pslot}/config.base" >& /dev/null; echo DATAROOT="${STMP}/RUNDIRS/${PSLOT}")"
    ln -sf ${HOMEgfs} ${EXPDIR}/GW-CODE 
    ln -sf ${HOMEgfs}/dev/workflow/rocoto_viewer.py ${EXPDIR}/rocoto_viewer.py
    ln -sf ${HOMEgfs}/dev/parm/config ${EXPDIR}/ORIG_CONFIGS
    ln -sf ${COMROOT}/logs ${EXPDIR}/LOGS_COMROOT
    ln -sf ${DATAROOT} ${EXPDIR}/DATAROOT
done
echo "FINISHED: soft-linking to EXPDIR"
}

################################################
# add dates to yamls to run for SFS baseline 
sfs_baseline () {
YAMLS=${@:1}
local YAML
for YAML in ${YAMLS}; do
    pslot=$(basename ${YAML/.yaml*})_$(basename ${HOMEgfs})
    EXPDIR=${RUNTESTS}/EXPDIR/${pslot}
    XML_FILE=${EXPDIR}/${pslot}.xml
    line=$(grep -n 'cycledef group' ${XML_FILE} | cut -d: -f1) 
    sed -i ${line}d ${XML_FILE}
    MONTHS="05 11"
    for Y in $(seq 1994 2023); do
        for M in ${MONTHS}; do 
            text="<cycledef group='"gefs"'>${Y}${M}010000 ${Y}${M}010000 24:00:00</cycledef>"
            sed -i "${line} i   ${text}" ${XML_FILE}
            line=$(( line + 1))
        done
    done
    echo "Added all SFS dates to ${XML_FILE}"
done
}

################################################
# add to cronttab if not currenting in crontab 
add_to_crontab () {
machine=${1}
YAMLS=${@:2}
if [[ ${machine} == gaea* ]] || [[ ${machine} == GAEA* ]]; then
    ct=scrontab
else
    ct=crontab
fi
for YAML in ${YAMLS}; do
    pslot=$(basename ${YAML/.yaml*})_$(basename ${HOMEgfs})
    f=${RUNTESTS}/EXPDIR/${pslot}/${pslot}
    exist=$( ${ct} -l | grep ${f} 2>/dev/null | wc -l )
    if (( ${exist} > 0 )); then
        echo "Already in Crontab ${pslot}"
    else
        echo "Adding to crontab: ${YAML}.crontab"
        ${ct} -l | cat - ${f}.crontab | ${ct} -
    fi
done
}

