#!/bin/bash
set -u
WAV_RES='mx025gefs tripolar a b'
WAV_NMPI='128 256 384 428 512' 
for res in ${WAV_RES}; do
for nmpi in ${WAV_NMPI}; do
    export WAV_RES=$res
    export WAV_NMPI=$nmpi
    ./RUN-WAV_NMPI_TEST.sh
    #exit 1
done
done
