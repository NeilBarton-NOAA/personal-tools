#!/bin/sh
set -u
########################
# remove Regression Testings
########################

topdirectory=${NPB_WORKDIR}/RUNs/RTs
delete=F
clean=F
while getopts td:d:c:h: flag; do
    case "${flag}" in
        td) topdirectory=${OPTARG};;
        d)  delete=${OPTARG};;
        c)  clean=${OPTARG};;
    esac
done


TOPDIR=$NPB_WORKDIR/RUNs/RTs

ds=$(ls -d $TOPDIR/cpld*/)
print=T
for d in $ds; do
  if [[ $clean == T ]]; then
    [[ $print == T ]] && echo 'Removing Large Files:'; print=F
    echo $d
    rm ${d}/*nc 2>/dev/null
    rm ${d}/RESTART/*nc 2>/dev/null
    rm ${d}/INPUT/*nc 2>/dev/null
    rm ${d}/history/*nc 2>/dev/null
  elif [[ ! -f $d/ESMF_Profile.summary ]]; then
    if [[ $delete == T ]]; then 
        [[ $print == T ]] && echo 'Removing:'
        echo $d
        rm -r $d
    else
        [[ $print == T ]] && echo 'Did Not Finish:'
        echo $d
    fi
    print=F 
  fi
done

[[ $print == T ]] && echo 'No Unfinished Runs Found at '$TOPDIR
