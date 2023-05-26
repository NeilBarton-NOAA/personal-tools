#!/bin/sh
########################
# wget data from nsidc
# sign-in information at ~/.netrc
set -u
TYPES='nasateam bootstrap'
SITE=https://daacdata.apps.nsidc.org/pub/DATASETS/nsidc0192_seaice_trends_climo_v3/total-ice-area-extent 
TOP_DIR=${NPB_WORKDIR}/DIAG/OBS/ice_extent
for T in ${TYPES}; do
    wget load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies \
        --no-check-certificate --auth-no-challenge=on \
        -nv -m \
        -P  ${TOP_DIR}/${T} \
        -A "*daily*" \
        -R 'index.html' \
        -r -l1 -np -nd "${SITE}/${T}"
done
