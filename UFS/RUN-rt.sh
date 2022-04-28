#!/bin/sh
set -u
source $PWD/MACHINE-config.sh
TEST_DIR=$WORKDIR/ufs-weather-model/tests
export ACCNR=marine-cpu
${TEST_DIR}/rt.sh -k -l rt.conf >& my_test.out & 

