#!/bin/sh
set -u
source $PWD/MACHINE-config.sh
test_case=cpld_control_p8
REPO=NeilBarton-NOAA 
CODE_DIR=$NPB_WORKDIR/CODE/ufs-weather-model_${REPO}

#case="RUN     | cpld_control_p8 | - hera | fv3 | "
case="
COMPILE | -DAPP=NG-GODAS            | - hera        | fv3 |
RUN     | datm_cdeps_control_cfsr   | - hera        | fv3 |
"
############
# run tests
cat << EOF > RUN_CASE
$case
EOF
export STMP=${NPB_WORKDIR}/../
export PTMP=${NPB_WORKDIR}/../
echo $case
${CODE_DIR}/tests/rt.sh -k -l $PWD/RUN_CASE

rm RUN_CASE

