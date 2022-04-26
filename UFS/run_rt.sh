#!/bin/sh
set -u
TEST_DIR=/work/noaa/marine/nbarton/ufs-weather-model/tests
export ACCNR=marine-cpu
${TEST_DIR}/rt.sh -k -l rt.conf >& my_test.out & 

