#!/bin/sh
set -u
# WGET Data
# https://nsidc.org/data/nsidc-0051/versions/2#anchor-2
DIR=/work/noaa/marine/nbarton/DIAG/OBS/ice_concentration/nsidc-0051

${PWD}/nsidc-download.py -d ${DIR} -s 20191201 

