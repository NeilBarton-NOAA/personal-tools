#!/bin/sh
set -xu

case ${EXP} in 
    'HR1' ) DIR_HPSS="/NCEPDEV/emc-climate/5year/Jiande.Wang/WCOSS2/HR1";;
    'EP4' ) DIR_HPSS='/NCEPDEV/emc-ensemble/2year/Bing.Fu/ep4/ep4_f';;
    * ) echo 'FATAL: case unknowned ' && exit 1
esac
