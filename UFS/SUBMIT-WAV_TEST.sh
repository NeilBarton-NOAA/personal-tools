#!/bin/bash
set -u
WAV_RESS='mx025gefs tripolar a b'
WAV_NMPIS='128 256 384 428 512' 
for res in ${WAV_RESS}; do
for nmpi in ${WAV_NMPIS}; do
    echo $res $nmpi
    export WAV_RES=$res
    export WAV_NMPI=$nmpi
    ./RUN-WAV_NMPI_TEST.sh
    ##exit 1
done
done
