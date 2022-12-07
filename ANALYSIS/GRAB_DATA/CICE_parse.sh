#!/bin/sh
set -u
# parse CICE files with variables
work_dir=$1
out_file=$2
vars="aice_h,tarea,hi_h,hs_h,TLAT,TLON,Tsfc_h,albsni_h"
dtg=${out_file: -13} && dtg=${dtg:0:10}

# function to parse files
CICE_PARSE(){
in_file=$1
out_tau_file=$2
temp_file=$( dirname ${in_file})/CICE_VARS_IC.nc
tau=${out_tau_file: -6:3}
if [[ ! -f ${out_tau_file} ]]; then
    ncks -v ${vars} ${in_file} ${temp_file}
    ncap2 -s "tau=$tau" ${temp_file} ${out_tau_file}
    rm ${temp_file} 
fi
echo "CREATED:" ${out_tau_file}
}

############
#   IC file
in_file=$(ls ${work_dir}/gfs.${dtg:0:8}/${dtg: -2}/ice/iceic*nc)
tau=000
out_tau_file=$(dirname ${in_file})/CICE_${dtg}_${tau}.nc
CICE_PARSE ${in_file} ${out_tau_file}
file_tau_list="${out_tau_file}"

############
# tau files
files=$(ls ${work_dir}/gfs.${dtg:0:8}/${dtg: -2}/ice/ice2*.nc)
for f in ${files}; do
    f_dtg=$(basename ${f}) && f_dtg=${f_dtg:3:10}
    tau=$( ~/STUDIES/TIME_TOOLS/CALC-TAU.sh ${dtg} ${f_dtg}) && tau=$(printf "%03d" $tau)
    out_tau_file=$(dirname ${f})/CICE_${dtg}_${tau}.nc
    CICE_PARSE ${f} ${out_tau_file}
    file_tau_list=${file_tau_list}' '${out_tau_file}
done
ncecat -u tau ${file_tau_list} ${out_file}
   
echo "CREATED:" ${out_file}
echo " "
rm -r ${PWD}/gfs.${dtg:0:8}
