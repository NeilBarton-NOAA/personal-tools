#!/bin/bash
set -u
####################################

VAR=${1:-'PRES'}
#VARS="TMP UGRD VGRD DSWRF DLWRF USWRF ULWRF ICEC LCDC MCDC HCDC TCDC'
#taus=( $(seq 0 6 840) )
taus=( $(seq 6 6 840) )
#taus=( $(seq 0 24 48) )
# P8
declare -A EXPS
EXPS=( 
["P8T"]="/scratch1/NCEPDEV/stmp2/Lydia.B.Stefanova/fromHPSS/ufs_p8"
["P8G"]="/scratch1/NCEPDEV/stmp2/Lydia.B.Stefanova/fromHPSS/ufs_p8_gm"
)


WGRIB2_TO_NETCDF(){
VAR=$1 && shift
temp_nc_file=$1 && shift
files=$@
for f in ${files}; do
    #echo '    from: ' ${f}
    wgrib2 ${f} -match ":${VAR}:" -append -netcdf ${temp_nc_file} 1>/dev/null 
    (( $? > 0 )) && echo 'wgrib2 failed' && exit 1
done
}

ERROR_CHECK(){
ec=$1
in_file=$2
if (( $ec == 0 )); then
    rm ${in_file}
else
    exit 1
fi
}

f_search='sfluxgrb'
if [[ ${VAR} == 'CLMR' ]]; then
    f_search='pgrb2.1p00'
fi
####################################
for EXP in "${!EXPS[@]}"; do
    echo $EXP
    SAVE_DIR=${NPB_WORKDIR}/UFS_OUTPUT/${EXP}
    mkdir -p ${SAVE_DIR}
    file_tau_list=''
    n_taus=${#taus[@]}
    last_tau=0 && start_n=0 && n=8
    while [[ $last_tau != ${taus[@]: -1} ]]; do
        ptaus=( ${taus[@]:${start_n}:${n}} )
        echo 'parrallel taus:' ${ptaus[@]}
        for tau in ${ptaus[@]}; do
            tau=$(printf "%03d" $tau)
            files=$(ls ${EXPS[$EXP]}/*/gfs*/00/atmos/gfs.*${f_search}*${tau}* )
            nc_file=${SAVE_DIR}/WORKING_DIR/${VAR}_${tau}.nc
            temp_nc_file=${SAVE_DIR}/WORKING_DIR/temp_${VAR}_${tau}.nc
            if [[ ! -f ${nc_file} ]]; then
                echo 'creating: ' ${temp_nc_file}
                WGRIB2_TO_NETCDF ${VAR} ${temp_nc_file} ${files} &
            fi
        done
        wait
        # add tau data
        for tau in ${ptaus[@]}; do
            tau=$(printf "%03d" $tau)
            nc_file=${SAVE_DIR}/WORKING_DIR/${VAR}_${tau}.nc
            temp_nc_file=${SAVE_DIR}/WORKING_DIR/temp_${VAR}_${tau}.nc
            if [[ ! -f ${nc_file} ]]; then
                echo "NCAP2 tau:" ${nc_file}
                ncap2 -s "tau=$tau" ${temp_nc_file} ${nc_file}
                (( $? > 0 )) && echo 'ncap2 tau failed' && exit 1
                rm ${temp_nc_file}
            fi
            file_tau_list=${file_tau_list}' '${nc_file}
        done
        start_n=$(( ${start_n} + ${n} ))
        last_tau=${ptaus[@]: -1}
    done
    if [[ ! -f ${SAVE_DIR}/gridarea.nc ]]; then
         cdo gridarea ${nc_file} ${SAVE_DIR}/gridarea.nc
    fi
    # cat taus
    #out_file=${SAVE_DIR}/${VAR}_TAU.nc
    out_file=${SAVE_DIR}/${VAR}.nc
    if [[ -f ${out_file} ]]; then 
        rm ${out_file}
    fi
    echo '  cat tau files' 
    ncecat -u tau ${file_tau_list} ${out_file}  
    (( $? > 0 )) && echo 'error in cat' && exit 1
    # remove unlimited dimension
    #in_file=${out_file}
    #out_file=${SAVE_DIR}/${VAR}_NO_UNLIMITED.nc
    #[[ ! -f ${out_file} ]] && echo '  removing unlimited dimensions' && ncks --fix_rec_dmn tau ${in_file} ${out_file}
    #exit 1
    #ERROR_CHECK $? ${in_file}
    #in_file=${out_file}
    #out_file=${SAVE_DIR}/${VAR}.nc
    #out_file=${SAVE_DIR}/TEMP.nc
    #[[ ! -f ${out_file} ]] && echo '  rearranging dimensions' && ncpdq -a time,tau,latitude,longitude ${in_file} ${out_file}
    #exit 1
    #ERROR_CHECK $? ${in_file}
    echo 'FINISHED: ' $out_file
done

