#!/bin/bash
set -u
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
NENS=${5:-20}
ICDIR=${6:-$NPB_WORKDIR/ICs}
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

############################################
# Times
DTG_YMD=${DTG:0:8}
DTG_HOUR=${DTG:8:10}
PTG=$(./DTG-add-time.sh ${DTG} -6 hours)
PTG_HOUR=${PTG:8:10}
PTG_YMD=${PTG:0:8}

############################################
# Default File Locations

########################
# files to find
atm_warm_ics='*ca_data.*.nc *coupler.res *fv_core.res.*.nc *fv_srf_wnd.res.*.nc *fv_tracer.res.*.nc *phy_data.*nc *sfc_data*.nc'
atm_cold_ics='gfs_ctrl.nc gfs_data*.nc sfc_data*.nc'
atm_bias_files='*abias* *radstat*'
med_ic='*ufs.cpld.cpl.r*'
ocn_ic='*MOM.res*nc'
ice_ic='*ice*.nc'
wav_ic='*ww3*'

#############################################
# loop through members
for MBR in $(seq -f '%03g' 0 ${NENS}); do
    FIND_DTG="${ICDIR}/${DTG}/mem${MBR} ${ICDIR}/gfs.${DTG_HOUR}.${DTG_YMD}"
    FIND_PTG="${ICDIR}/${DTG}/mem${MBR} ${ICDIR}/gfs.${PTG_HOUR}.${PTG_YMD}"
    DIR_PTG=${COMROT}/${CDUMP}.${PTG_YMD}/${PTG_HOUR}/mem${MBR}/model_data
    DIR_DTG=${COMROT}/${CDUMP}.${DTG_YMD}/${DTG_HOUR}/mem${MBR}/model_data
    ###########
    # ATMOS
    if [[ $APP == ATM || ${APP:0:3} == S2S ]]; then
        # first look for warm start files
        n_files=$(find -L ${FIND_PTG} -name "*fv_core.res*.nc" 2>/dev/null | wc -l)
        if (( ${n_files} != 0 )); then
            START=warm
            for f in ${atm_warm_ics}; do
                files=$(find -L ${FIND_PTG} -name "${f}" 2>/dev/null)
                LINK_FILES ${files} ${DIR_PTG}/atmos/restart
            done
        else # look for cold start files
            n_files=$(find -L ${FIND_DTG} -name "gfs_ctrl.nc" 2>/dev/null | wc -l)
            if (( ${n_files} == 0 )); then
                echo "FATAL: ATM restarts not found"
                exit 1
            fi
            START=cold
            for f in ${cold_files}; do
                files=$(find -L ${FIND_DTG} -name "${f}" 2>/dev/null)
                LINK_FILES ${files} ${DIR_DTG}/atmos/input
            done
        fi
        #bias files once
        #if (( ${MBR} == 0 )); then
        #    for f in ${bias_files}; do
        #        files=$(find -L ${FIND_DTG} -name "${f}" 2>/dev/null)
        #        LINK_FILES ${files} ${DIR_DTG}/atmos
        #    done
        #fi
    fi
    ###########
    # MEDIATOR/Coupler
    if [[ ${START} == 'warm' ]]; then
        file=$(find -L ${FIND_DTG} -name "${med_ic}" 2>/dev/null)
        LINK_FILES ${file} ${DIR_PTG}/med/restart
    fi
    ###########
    # OCN and ICE
    if [[ ${APP:0:3} == S2S ]]; then
        files=$(find -L ${FIND_DTG} -name "${ocn_ic}" 2>/dev/null)
        LINK_FILES ${files} ${DIR_PTG}/ocean/restart
        file=$(find -L ${FIND_PTG} -name "${ice_ic}" 2>/dev/null)
        LINK_FILES ${file} ${DIR_PTG}/ice/restart
    fi
    ###########
    # OCN and ICE
    if [[ ${APP} == S2SW* ]]; then
        files=$(find -L ${FIND_PT} -name "${wav_ic}" 2>/dev/null)
        LINK_FILES ${files} ${DIR_PTG}/wave/restart
    fi
done

