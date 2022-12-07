#!/bin/bash
set -u

TOPDIR=/lfs/h2/emc/gefstemp/rplout
WORKDIR=${NPB_WORKDIR}/REPLAY_DEMO

CICE_PARSE(){
in_file=$1
out_tau_file=$2
temp_file=$( dirname ${out_tau_file})/CICE_VARS_IC.nc
tau=${out_tau_file: -6:3}
#vars="aice_h,tarea,hi_h,hs_h,TLAT,TLON,Tsfc_h,albsni_h"
vars="aice_d,tarea,TLAT,TLON"
if [[ ! -f ${out_tau_file} ]]; then
    ncks -v ${vars} ${in_file} ${temp_file}
    ncap2 -s "tau=$tau" ${temp_file} ${out_tau_file}
    rm ${temp_file} 
fi
echo "CREATED:" ${out_tau_file}
}

for exp_dir in $(ls -d ${TOPDIR}/*/); do
    exp=$(basename ${exp_dir})
    for type_dir in $(ls -d ${exp_dir}*/); do
        type=$(basename ${type_dir})
        for dtg_dir in $(ls -d ${type_dir}*/); do
            dtg=$(basename ${dtg_dir})00
            work_dir=${WORKDIR}/${exp}/${type}
            mkdir -p ${work_dir}
            out_file=${work_dir}/CICE_${dtg}.nc
            if [[ ! -f ${out_file} ]]; then
                cice_files=$(ls ${dtg_dir}ice/iceh*nc)
                file_tau_list=""
                for full_f in ${cice_files}; do
                    f=$(basename ${full_f})
                    f_dtg=${f: -13 :4}${f: -8:2}${f: -5:2}00 
                    tau=$(~/STUDIES/TIME_TOOLS/CALC-TAU.sh ${dtg} ${f_dtg})
                    tau=$(printf "%03d" $tau)
                    out_tau_file=${work_dir}/CICE_${dtg}_${tau}.nc
                    CICE_PARSE ${full_f} ${out_tau_file}
                    file_tau_list=${file_tau_list}' '${out_tau_file}
                done
                echo ${out_file}
                ncecat -u tau ${file_tau_list} ${out_file}
                for f in ${file_tau_list}; do
                    rm $f
                done
            fi
        done
    done
done

#files=$(ls ${TOPDIR}/rpl/c00/*/ice/*nc)



