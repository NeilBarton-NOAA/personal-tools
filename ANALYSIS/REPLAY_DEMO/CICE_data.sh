#!/bin/bash
set -u

source ~/ANALYSIS/DATA_PARSE/CICE_parse.sh
source ~/.bashrc 1&2>/dev/null

TOPDIR=/lfs/h2/emc/gefstemp/rplout
WORKDIR=${NPB_WORKDIR}/REPLAY_DEMO
var=hi_d
EXPDIR=${TOPDIR}/ctl/c00
EXP=CTL

for DTGDIR in $(ls -d ${EXPDIR}/*/); do
    dtg=$(basename ${DTGDIR})00
    work_dir=${WORKDIR}/${EXP}
    mkdir -p ${work_dir}
    out_file=${work_dir}/${var}_${dtg}.nc
    if [[ ! -f ${out_file} ]]; then
        # parse variable from file
        cice_files=$(ls ${DTGDIR}/ice/iceh*nc)
        for full_f in ${cice_files}; do
            f=$(basename ${full_f})
            f_dtg=${f: -13 :4}${f: -8:2}${f: -5:2}00 
            tau=$(CALC-TAU.sh ${dtg} ${f_dtg})
            tau=$(printf "%03d" $tau)
            out_tau_file=${work_dir}/WORKING/${dtg}/${var}_${dtg}_${tau}.nc
            mkdir -p $(dirname ${out_tau_file})
            CICE_PARSE ${full_f} ${out_tau_file} ${var}
        done
        # add taus for one file per DTG
        file_tau_list=$(ls $(dirname ${out_tau_file})/${var}_${dtg}*.nc )
        ncecat -u tau ${file_tau_list} ${out_file}
        echo "CREATED:" ${out_file}
        rm -r $(dirname ${out_tau_file})/
    fi
done

# add transfer to HPSS
cd ${WORKDIR}
htar -cvf ${HTAR_HOME}/REPLAY/${EXP}_${var}.tar ${EXP}/*${var}*nc



