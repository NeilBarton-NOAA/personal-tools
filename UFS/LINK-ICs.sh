#!/bin/bash
########################
# Link ICs to COMROOT
########################
set -u
DTG=$1
COMROT=$2
#DTG=2019120300
#COMROT=TEST
APP=${3:-S2SW}
CDUMP=${4:-gfs}
ICDIR=${5:-$NPB_WORKDIR/ICs}
#NENS=${5:-20}
echo "LINKING ICs to $COMROT"
echo "  APP=${APP}"

LINK_FILES() {
  FILES=${@:1:$(($#-1))}
  DIR=${@: -1}
  mkdir -p ${DIR}
  for f in ${FILES}; do
    [[ ! -f ${f} ]] && echo "FATAL: file not found ${f}" && exit 1
    bn=$(basename $f)
    if [[ ${bn:0:3} == 'MOM' ]]; then
        bn=${DTG_YMD}.${DTG_HOUR}0000.${bn}
    fi
    #echo $f $DIR/${bn}
    ln -sf ${f} ${DIR}/${bn}
  done
}

DTG_YMD=${DTG:0:8}
DTG_HOUR=${DTG:8:10}
PTG=$(./DTG-add-time.sh ${DTG} -6 hours)
PTG_HOUR=${PTG:8:10}
PTG_YMD=${PTG:0:8}

if [[ $APP == ATM || ${APP:0:3} == S2S ]]; then
    warm_files='*ca_data.*.nc \
                *coupler.res \
                *fv_core.res.*.nc \
                *fv_srf_wnd.res.*.nc \
                *fv_tracer.res.*.nc \
                *phy_data.*nc \
                *sfc_data*.nc'
    cold_files='gfs_ctrl.nc gfs_data*.nc sfc_data*.nc'
    bias_files='*abias* *radstat*'
    # first look for warm start files
    n_files=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${PTG_HOUR}.${PTG_YMD} -name "*fv_core.res*.nc" 2>/dev/null | wc -l)
    if (( ${n_files} != 0 )); then
        START=warm
        for f in ${warm_files}; do
            files=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${PTG_HOUR}.${PTG_YMD} -name "${f}" 2>/dev/null)
            LINK_FILES ${files} ${COMROT}/${CDUMP}.${PTG_YMD}/${PTG_HOUR}/atmos/RESTART
        done
    else # look for cold start files
        n_files=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${DTG_HOUR}.${DTG_YMD} -name "gfs_ctrl.nc" 2>/dev/null | wc -l)
        if (( ${n_files} == 0 )); then
            echo "FTAL: ATM restarts not found"
            exit 1
        fi
        START=cold
        for f in ${cold_files}; do
            files=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${DTG_HOUR}.${DTG_YMD} -name "${f}" 2>/dev/null)
            LINK_FILES ${files} ${COMROT}/${CDUMP}.${DTG_YMD}/${DTG_HOUR}/atmos/INPUT
        done
    fi
    # TODO link enkf files if needed 
    # for mbr in $(seq -f '%03g' 1 $NENS); do
    #     LINK_FILES ${ICSDIR}/enkfgdas.${atmos_YMD}/${atmos_HOUR}/atmos/mem${mbr}/${atmos_dir} ${COMROT}/enkfgdas.${atmos_YMD}/${atmos_HOUR}/mem${mbr}/atmos/${atmos_dir}
    # done
    if [[ ${CDUMP} == 'gdas' ]]; then
        for f in ${bias_files}; do
            files=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${DTG_HOUR}.${DTG_YMD} -name "${f}" 2>/dev/null)
            LINK_FILES ${files} ${COMROT}/${CDUMP}.${DTG_YMD}/${DTG_HOUR}/atmos
        done
    fi
fi

if [[ ${START} == 'warm' ]]; then
    med_file='*ufs.cpld.cpl.r*'
    file=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${DTG_HOUR}.${DTG_YMD} -name "${med_file}" 2>/dev/null)
    LINK_FILES ${file} ${COMROT}/${CDUMP}.${PTG_YMD}/${PTG_HOUR}/med/RESTART
fi

if [[ ${APP:0:3} == S2S ]]; then
    mom6_file='*MOM.res*nc'
    files=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${PTG_HOUR}.${PTG_YMD} -name "${mom6_file}" 2>/dev/null)
    LINK_FILES ${files} ${COMROT}/${CDUMP}.${PTG_YMD}/${PTG_HOUR}/ocean/RESTART
    cice_file='*ice*nc'
    file=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${DTG_HOUR}.${DTG_YMD} -name "${cice_file}" 2>/dev/null)
    LINK_FILES ${file} ${COMROT}/${CDUMP}.${DTG_YMD}/${DTG_HOUR}/ice/RESTART 
fi

if [[ ${APP} == S2SW ]]; then
    wav_file='*ww3*'
    files=$(find ${ICDIR}/${DTG} ${ICDIR}/gfs.${DTG_HOUR}.${DTG_YMD} -name "${wav_file}" 2>/dev/null)
    LINK_FILES ${files} ${COMROT}/${CDUMP}.${DTG_YMD}/${DTG_HOUR}/wave
fi
