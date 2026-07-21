#!/bin/sh
set -u
################################################
# Machine Specific and Personalized options
machine_config() {
export RUNTESTS=${NPB_WORKDIR}/RUNS #/gw_${HASH////\_}_${REPO}
export EXPDIR_TOP=${HOME}/GW
export CODEDIR=${NPB_WORKDIR}
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
             TOPICDIR=/scratch4/NCEPDEV/global/Yangxing.Zheng/ICs ;
             export CODEDIR=/scratch4/NCEPDEV/nems/Neil.Barton ;;
*[cd]login*) m=wcoss2 ;
             TOPICDIR=/lfs/h2/emc/couple/noscrub/neil.barton/ICs ;
             export CODEDIR=/lfs/h2/emc/couple/noscrub/neil.barton ;;
*)           echo "MACHINE unknown:" ${machine} && exit 1;;
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
    for f in $( find ${HOMEglobal}/dev/ci/cases/pr -name *.yaml | xargs grep -l --exclude="*ecflow*" forecast-only | xargs grep -L ${m} ); do YAMLS+=("$f"); done
fi 
if [[ ${CI_DA} == T ]]; then
    for f in $( find ${HOMEglobal}/dev/ci/cases/pr -name *.yaml | xargs grep -l --exclude="*ecflow*" cycled | xargs grep -L ${m} ); do YAMLS+=("$f"); done
fi 
for Y in ${YAMLS[@]}; do 
    [[ ! -f ${Y} ]] &&  echo "FATAL YAML NOT FOUND. ${Y}" && exit 1
    if [[ ${PSLOT_NAME:-'default'} == 'default' ]]; then
        pslot=$(basename ${Y/.yaml*})_$(basename ${HOMEglobal})
        PSLOTS+=("${pslot}")
    else
        #set -x
        pslot=${PSLOT_NAME}
        #check to see if already exist
        if [[ -d ${EXPDIR_TOP}/EXPDIR/${pslot} ]]; then
            n=1
            ds=$( ls -d ${EXPDIR_TOP}/EXPDIR/*/ )
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
HOMEglobal=${1}
HASH=${2}
REPO=${3}
if [[ ! -d ${HOMEglobal} ]]; then
    ORDIR=${PWD}
    TOPDIR=${HOMEglobal}/../
    mkdir -p ${TOPDIR} && cd ${TOPDIR}
    git clone --recursive -b ${HASH} git@github.com:${REPO}/global-workflow.git $(basename ${HOMEglobal})
    [[ $? > 0 ]] && exit 1
    cd ${ORDIR}
fi
}

################################################
# Update gw if needed
update_gw () {
HOMEglobal=${1}
ORIG_DIR=${PWD}
cd ${HOMEglobal}
git pull 
git submodule update --init --recursive -j 10
cd ${ORIG_DIR}
}
################################################
# Build only gw options that are needed 
build_gw () {
HOMEglobal=${1}
ACCOUNT=${2}
# Check what options need to be compiled
NETS=()
for f in ${YAMLS[@]}; do
    net=$( grep net ${f} | awk '{print $2}' )
    NETS+=("${net}")
done
CYCLED=$( grep cycled ${YAMLS[@]} 2>/dev/null | wc -l )
if [[ ${CYCLED} > 0 ]]; then
    NETS+=("gsi")
    NETS+=("gdas")
fi
readarray -t OPTIONS < <(printf "%s\n" "${NETS[@]}" | sort -u)
for i in "${!OPTIONS[@]}"; do
    if [[ -f ${HOMEglobal}/exec/ufs_model_${OPTIONS[$i]}.x || -f ${HOMEglobal}/exec/ufs_model_${OPTIONS[$i]}.x ]]; then
        unset "OPTIONS[$i]"
    fi
done
cd ${HOMEglobal}/sorc
if [[ ${#OPTIONS[@]} -gt 0 ]]; then
    echo "Building: ${OPTIONS[@]}"
    ./build_all.sh "${OPTIONS[@]}" #>& ~/GW/build_$(basename ${HOMEgfs}).log &
    ./link_workflow.sh
fi
}

################################################
# Run create_experiment script 
create_experiment () {
HOMEglobal=${1}
machine=${2}
export HPC_ACCOUNT=${3}
source ${HOMEglobal}/dev/ci/platforms/config.${machine/.*}
source ${HOMEglobal}/dev/ush/gw_setup.sh >& /dev/null
export HPC_ACCOUNT=${COMPUTE_ACCOUNT}
for (( i=0; i<${#YAMLS[@]}; i++ )); do
    YAML=${YAMLS[${i}]}
    export pslot=${PSLOTS[${i}]}
    echo "create_experiment.py: ${YAML}, ${pslot}"
    ${HOMEglobal}/dev/workflow/create_experiment.py --yaml "${YAML}"
    eval "$(PDY=0 cyc=0 source "${EXPDIR_TOP}/EXPDIR/${pslot}/config.base" >& /dev/null; echo DATAROOT="${STMP}/RUNDIRS/${PSLOT}")"
    echo ${DATAROOT}
    if [[ -d ${DATAROOT} ]]; then
        echo "DATAROOT exist: ${DATAROOT}" 
        read -p "  remove [y/N]?: " input
        if [[ "$input" == "y" || "$input" == "Y" ]]; then
            rm -r ${DATAROOT}
        fi
    fi
done
}

################################################
# link items to EXPDIR for personal debugging 
link_EXPDIR () {
HOMEglobal=${1}
#[[ ! -d ${HOME}/GW/EXPDIR ]] && ln -sf ${RUNTESTS}/EXPDIR ${HOME}/GW/EXPDIR 
for (( i=0; i<${#YAMLS[@]}; i++ )); do
    YAML=${YAMLS[${i}]}
    pslot=${PSLOTS[${i}]}
    local EXPDIRpslot=${EXPDIR_TOP}/EXPDIR/${pslot}
    COMROOT=${RUNTESTS}/COMROOT/${pslot}
    eval "$(PDY=0 cyc=0 source "${EXPDIRpslot}/config.base" >& /dev/null; echo DATAROOT="${STMP}/RUNDIRS/${PSLOT}")"
    ln -sf ${HOMEglobal} ${EXPDIRpslot}/GW-CODE 
    ln -sf ${HOMEglobal}/dev/workflow/rocoto_viewer.py ${EXPDIRpslot}/rocoto_viewer.py
    ln -sf ${HOMEglobal}/dev/workflow/setup_workflow.py ${EXPDIRpslot}/setup_workflow.py
    ln -sf ${HOMEglobal}/dev/parm/config ${EXPDIRpslot}/ORIG_CONFIGS
    ln -sf ${COMROOT}/logs ${EXPDIRpslot}/LOGS_COMROOT
    ln -sf ${DATAROOT} ${EXPDIRpslot}/DATAROOT
    ln -sf ${HOMEglobal}/dev/ush/gw_setup.sh ${EXPDIRpslot}/gw_setup.sh
done
echo "FINISHED: soft-linking to EXPDIRpslot"
}

################################################
# add dates to yamls to run for SFS baseline 
sfs_baseline () {
MONTHS=${1:-"05 11"}
for (( i=0; i<${#YAMLS[@]}; i++ )); do
    YAML=${YAMLS[${i}]}
    pslot=${PSLOTS[${i}]}
    local EXPDIRpslot=${EXPDIR}/EXPDIR/${pslot}
    XML_FILE=${EXPDIRpslot}/${pslot}.xml
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
    f=${EXPDIR_TOP}/EXPDIR/${pslot}/${pslot}
    exist=$( ${ct} -l | grep ${f} 2>/dev/null | wc -l )
    if (( ${exist} > 0 )); then
        echo "Already in Crontab ${pslot}"
    else
        echo "Adding to crontab: ${YAML}.crontab"
        ${ct} -l | cat - ${f}.crontab | ${ct} -
    fi
done
}

