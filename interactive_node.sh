#!/bin/sh
# hera/orion

DEBUG=${1:-F}
machine=$(uname -n)
if [[ ${machine} == u* ]]; then
    # ursa
    if [[ ${DEBUG} == T ]]; then
        salloc --x11=first -q debug -t 0:30:00 --nodes=1 -A marine-cpu --exclusive
    else
        salloc --x11=first -t 2:00:00 --nodes=1 -A marine-cpu --exclusive
    fi
elif [[ ${machine} == gaea* ]]; then
    echo "gaea"
    salloc --x11=first -t 4:00:00 --qos=hpss --partition=dtn_f5_f6 --constraint=f6 --nodes=1 -A ira-da #--exclusive
fi
source ~/.bashrc



#SBATCH --account=sfs-cpu
#SBATCH --qos=hpss
#SBATCH --partition=dtn_f5_f6
#SBATCH --constraint=f6

