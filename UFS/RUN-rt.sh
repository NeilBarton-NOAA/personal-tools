#!/bin/sh
set -u
source $PWD/MACHINE-config.sh
TEST_DIR=$NPB_WORKDIR/ufs-weather-model/tests
export ACCNR=marine-cpu
${TEST_DIR}/rt.sh -k -l $PWD/CONF/rt.conf >& ~/rt_test.out & 

