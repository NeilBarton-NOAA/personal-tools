#! /usr/bin/env bash
set -u

# P8
declare -A EXPS
EXPS=( 
["P8T"]="/NCEPDEV/emc-climate/5year/role.ufscpara/HERA/prototype8"
["P8G"]="/ESRL/BMC/fim/5year/Ben.Green/WPO_S2S_35d_output/P8_20220810_GFDLMP/"
)
model=CICE
[[ ${model} == CICE ]] && f2d=ice.tar

for EXP in "${!EXPS[@]}"; do
    work_dir=${NPB_WORKDIR}/UFS_OUTPUT/${EXP}/WORKING_DIR
    mkdir -p ${work_dir} 
    dir=${EXPS[$EXP]}
    files=$(hsi -q ls ${dir}/*/${f2d} 2>&1 | grep :)
    for f in ${files}; do
        f_get=${f::-1}/${f2d}
        dtg=$(dirname ${f_get}) && dtg=${dtg: -10}
        out_file=${work_dir}/${model}_${dtg}.nc
        if [[ ! -f ${out_file} ]]; then
submit_file=~/STUDIES/${dtg}_submit
cat<<EOF > ${submit_file}
#!/bin/sh -l
#SBATCH -J down${dtg}
#SBATCH --partition=service
#SBATCH --time=12:00:00
#SBATCH -o %x.o%j
#SBATCH --ntasks=1
#SBATCH --exclusive #may mean use all memory
#SBATCH -A marine-cpu

f_get=${f_get}
model=${model}
out_file=${out_file}
work_dir=${work_dir}

cd ${work_dir}
# download files
htar -xvf ${f_get}
# parse files
~/STUDIES/${model}_parse.sh ${work_dir} ${out_file}
if (( $? > 0 )); then
    echo 'parse failed' ${model}
    exit 1
fi
EOF

sbatch ${submit_file}
        fi
    done
done
