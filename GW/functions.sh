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
[[ -z "${YAMLS+x}" ]] && YAMLS=()
PSLOTS=()
if [[ ${DEFAULT_YAMLS} == T ]]; then
    for f in $( find ${PWD}/YAMLS -name C*.yaml ); do YAML+=("${f}"); done
fi
if [[ ${CI_FORECAST} == T ]]; then
    for f in $( find ${HOMEgfs}/dev/ci/cases/pr -name *.yaml | xargs grep -l --exclude="*ecflow*" forecast-only | xargs grep -L ${m} ); do YAMLS+=("$f"); done
fi 
if [[ ${CI_DA} == T ]]; then
    for f in $( find ${HOMEgfs}/dev/ci/cases/pr -name *.yaml | xargs grep -l --exclude="*ecflow*" cycled | xargs grep -L ${m} ); do YAMLS+=("$f"); done
fi 
for Y in ${YAMLS[@]}; do 
    [[ ! -f ${Y} ]] &&  echo "FATAL YAML NOT FOUND. ${Y}" && exit 1
    if [[ ${PSLOT_NAME:-'default'} == 'default' ]]; then
        pslot=$(basename ${Y/.yaml*})_$(basename ${HOMEgfs})
        PSLOTS+=("${pslot}")
    else
        #set -x
        pslot=${PSLOT_NAME}
        #check to see if already exist
        if [[ -d ${RUNTESTS}/EXPDIR/${pslot} ]]; then
            n=1
            ds=$( ls -d ${RUNTESTS}/EXPDIR/*/ )
            e_pslot=()
            for d in ${ds}; do
                n_pslot=$(basename ${d})
                e_pslot+=("${n_pslot}")
            done
            while true; do
                f_n=$(printf %02d ${n})
                temp_pslot=${pslot}_${f_n}
                if [[ ! " ${e_pslot[@]} " =~ " ${temp_pslot} " ]]; then
                    break
                fi
                n=$(( n + 1 ))
            
            done
            pslot=${temp_pslot}
        fi
        PSLOTS+=("${pslot}")
    fi
    echo "${Y}, ${pslot}"
done
export YAMLS PSLOTS
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
# Update gw if needed
update_gw () {
HOMEgfs=${1}
ORIG_DIR=${PWD}
cd ${HOMEgfs}
git pull 
git submodule update --init --recursive -j 10
cd ${ORIG_DIR}
}
################################################
# Build only gw options that are needed 
build_gw () {
HOMEgfs=${1}
ACCOUNT=${2}
# Check what options need to be compiled
NETS=()
for f in ${YAMLS[@]}; do
    net=$( grep net ${f} | awk '{print $2}' )
    NETS+=("${net}")
done 
readarray -t OPTIONS < <(printf "%s\n" "${NETS[@]}" | sort -u)
for i in "${!OPTIONS[@]}"; do
    if [[ -f ${HOMEgfs}/exec/${OPTIONS[$i]}_model.x ]]; then
        unset "OPTIONS[$i]"
    fi
done
cd ${HOMEgfs}/sorc
if [[ ${#OPTIONS[@]} -gt 0 ]]; then
    echo "Building: ${OPTIONS[@]}"
    ./build_all.sh "${OPTIONS[@]}" #>& ~/GW/build_$(basename ${HOMEgfs}).log &
    ./link_workflow.sh
fi
}

################################################
# Run create_experiment script 
create_experiment () {
HOMEgfs=${1}
machine=${2}
export HPC_ACCOUNT=${3}
source ${HOMEgfs}/dev/ci/platforms/config.${machine/.*}
source ${HOMEgfs}/dev/ush/gw_setup.sh >& /dev/null
export HPC_ACCOUNT=${COMPUTE_ACCOUNT}
for (( i=0; i<${#YAMLS[@]}; i++ )); do
    YAML=${YAMLS[${i}]}
    export pslot=${PSLOTS[${i}]}
    echo "create_experiment.py: ${YAML}, ${pslot}"
    ${HOMEgfs}/dev/workflow/create_experiment.py --yaml "${YAML}"
    eval "$(PDY=0 cyc=0 source "${RUNTESTS}/EXPDIR/${pslot}/config.base" >& /dev/null; echo DATAROOT="${STMP}/RUNDIRS/${PSLOT}")"
    echo ${DATAROOT}
    if [[ -d ${DATAROOT} ]]; then
        echo "DATAROOT exist: ${DATAROOT}" 
        read -p "  remove [y/N]?: " -r -n 1 
        echo 
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -r ${DATAROOT}
        fi
    fi
done
}

################################################
# link items to EXPDIR for personal debugging 
link_EXPDIR () {
HOMEgfs=${1}
[[ ! -d ${HOME}/GW/EXPDIR ]] && ln -sf ${RUNTESTS}/EXPDIR ${HOME}/GW/EXPDIR 
for (( i=0; i<${#YAMLS[@]}; i++ )); do
    YAML=${YAMLS[${i}]}
    pslot=${PSLOTS[${i}]}
    EXPDIR=${RUNTESTS}/EXPDIR/${pslot}
    COMROOT=${RUNTESTS}/COMROOT/${pslot}
    eval "$(PDY=0 cyc=0 source "${RUNTESTS}/EXPDIR/${pslot}/config.base" >& /dev/null; echo DATAROOT="${STMP}/RUNDIRS/${PSLOT}")"
    ln -sf ${HOMEgfs} ${EXPDIR}/GW-CODE 
    ln -sf ${HOMEgfs}/dev/workflow/rocoto_viewer.py ${EXPDIR}/rocoto_viewer.py
    ln -sf ${HOMEgfs}/dev/workflow/setup_workflow.py ${EXPDIR}/setup_workflow.py
    ln -sf ${HOMEgfs}/dev/parm/config ${EXPDIR}/ORIG_CONFIGS
    ln -sf ${COMROOT}/logs ${EXPDIR}/LOGS_COMROOT
    ln -sf ${DATAROOT} ${EXPDIR}/DATAROOT
done
echo "FINISHED: soft-linking to EXPDIR"
}

################################################
# add dates to yamls to run for SFS baseline 
sfs_baseline () {
MONTHS=${1:-"05 11"}
for (( i=0; i<${#YAMLS[@]}; i++ )); do
    YAML=${YAMLS[${i}]}
    pslot=${PSLOTS[${i}]}
    EXPDIR=${RUNTESTS}/EXPDIR/${pslot}
    XML_FILE=${EXPDIR}/${pslot}.xml
    line=$(grep -n 'cycledef group' ${XML_FILE} | cut -d: -f1) 
    sed -i ${line}d ${XML_FILE}
    for Y in $(seq 1994 2023); do
        for M in ${MONTHS}; do 
            text="<cycledef group='"sfs"'>${Y}${M}010000 ${Y}${M}010000 06:00:00</cycledef>"
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
if [[ ${machine} == gaea* ]] || [[ ${machine} == GAEA* ]]; then
    ct=scrontab
else
    ct=crontab
fi
for (( i=0; i<${#YAMLS[@]}; i++ )); do
    YAML=${YAMLS[${i}]}
    pslot=${PSLOTS[${i}]}
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

