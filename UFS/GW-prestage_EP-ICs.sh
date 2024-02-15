#!/bin/bash
set -u
########################
# Put ICs in format expected by g-w for EP experiments
########################
set -u
#DTG=$1
DTG=2017100400
TOP_SRCDIR=${2:-${NPB_WORKDIR}/ICs}
#TOP_SRCDIR=${2:-/lfs/h2/emc/gefstemp/Bing.Fu/ep5ic}
TOP_DESDIR=${3:-${NPB_WORKDIR}/ICs}
NENS=${4:-1}
APP=${5:-S2SWA}

########################
# Link and rename files if needed
LINK_FILES() {
  FILES=${@:1:$(($#-1))}
  DIR=${@: -1}
  mkdir -p ${DIR}
  for f in ${FILES}; do
    [[ ! -f ${f} ]] && echo "FATAL: file not found ${f}" && exit 1
    bn=$(basename $f)
    if [[ ${bn:0:3} == 'MOM' ]]; then
        bn=${PDY}.${cyc}0000.${bn}
    fi
    if [[ ${bn} == mem*pert.nc ]]; then
        bn=${PDY}.${cyc}0000.mom6_increment.nc
    fi
    if [[ ${bn} == *ice* ]]; then
        bn=${PDY}.${cyc}0000.cice_model.res.nc
    fi
    if [[ ${bn} == *ww3* ]]; then
        bn=${PDY}.${cyc}0000.restart.glo_025
    fi
    echo ${f} ${DIR}/${bn}
    ln -sf ${f} ${DIR}/${bn}
  done
}

########################
# DTG options
PDY=${DTG:0:8}
cyc=${DTG:8:10}

########################
# files to find
atm_warm_ics='*ca_data.*.nc *coupler.res *fv_core.res.*.nc *fv_srf_wnd.res.*.nc *fv_tracer.res.*.nc *phy_data.*nc *sfc_data*.nc'
atm_cold_ics='gfs_ctrl.nc gfs_data*.nc sfc_data*.nc'
med_ic='*ufs.cpld.cpl.r*'
ocn_ic='*ORA*nc'
ice_ic="*${DTG}*.nc"
wav_ic='*ww3'

#############################################
# loop through members
for MBR in $(seq -f '%03g' 0 ${NENS}); do
    echo "MEMBER: ${MBR} ${MBR:1:2}"
    ########################
    # directory options
    #   source 
    ATM_SRC=${TOP_SRCDIR}/gfs/aero/gefs.${PDY}/${cyc}/?${MBR:1:2}
    OCN_SRC=${TOP_SRCDIR}/ocn/${PDY}
    OCNPERT_SRC=${TOP_SRCDIR}/ocn/${DTG}
    ICE_SRC=${TOP_SRCDIR}/ice
    WAV_SRC=${TOP_SRCDIR}/wav/${PDY}
    #   destination
    ATM_DES=${TOP_DESDIR}/${PDY}${cyc}/mem${MBR}/atmos
    OCN_DES=${TOP_DESDIR}/${PDY}${cyc}/mem${MBR}/ocean
    ICE_DES=${TOP_DESDIR}/${PDY}${cyc}/mem${MBR}/ice
    WAV_DES=${TOP_DESDIR}/${PDY}${cyc}/mem${MBR}/wave
    MED_DES=${TOP_DESDIR}/${PDY}${cyc}/mem${MBR}/med
    ###########
    # ATMOS
    if [[ $APP == ATM || ${APP:0:3} == S2S ]]; then
        echo ${ATM_SRC}
        # EP files are cold starts
        n_files=$(find -L ${ATM_SRC} -name "gfs_ctrl.nc" 2>/dev/null | wc -l)
        if (( ${n_files} == 0 )); then
            echo "FATAL: ATM restarts not found"
            exit 1
        fi
        START=cold
        for f in ${atm_cold_ics}; do
            files=$(find -L ${ATM_SRC} -name "${f}" 2>/dev/null)
            LINK_FILES ${files} ${ATM_DES}
        done
        # surface data
        ATM_SRC=${TOP_SRCDIR}/gfs/aero/sfcspin/${DTG}
        files=$(find -L ${ATM_SRC} -name "*sfc_data*nc" 2>/dev/null)
        LINK_FILES ${files} ${ATM_DES}
    fi
    ###########
    # MEDIATOR/Coupler
    if [[ ${START} == 'warm' ]]; then
        file=$(find -L ${MED_SRC} -name "${med_ic}" 2>/dev/null)
        LINK_FILES ${file} ${MED_DES}
    fi
    ###########
    # OCN and ICE
    if [[ ${APP:0:3} == S2S ]]; then
        files=$(find -L ${OCN_SRC} -name "${ocn_ic}" 2>/dev/null)
        LINK_FILES ${files} ${OCN_DES}
        if (( ${MBR} > 0 )); then
            ocnpert_ic="mem${MBR}_pert.nc"
            files=$(find -L ${OCNPERT_SRC} -name "${ocnpert_ic}" 2>/dev/null)
            LINK_FILES ${files} ${OCN_DES}
        fi 
        file=$(find -L ${ICE_SRC} -name "${ice_ic}" 2>/dev/null)
        LINK_FILES ${file} ${ICE_DES}
    fi
    ###########
    # WAVES
    if [[ ${APP} == S2SW* ]]; then
        files=$(find -L ${WAV_SRC} -name "?${MBR:1:2}*${wav_ic}" 2>/dev/null)
        LINK_FILES ${files} ${WAV_DES}
    fi
done

