#!/bin/bash
set -u
# Functions to parse CICE data

CICE_PARSE(){
in_file=$1
out_tau_file=$2
var=${3:-'aice_d'}
temp_file=$( dirname ${out_tau_file})/CICE_VARS_IC.nc
tau=${out_tau_file: -6:3}
if [[ ! -f ${out_tau_file} ]]; then
    ncks -v "${var},tarea,TLAT,TLON" ${in_file} ${temp_file}
    ncap2 -s "tau=$tau" ${temp_file} ${out_tau_file}
    rm ${temp_file} 
fi
echo "CREATED:" ${out_tau_file}
}

