#!/bin/sh
set -u
####################################
# set up GW runs with YAML file
# CI yamls can be found at ${HOMEgfs}/ci/cases/{pr/weekly}/
####################################
# Code
XML_FILE=${1}

echo ${XML_FILE}
line=$(grep -n 'cycledef group' ${XML_FILE} | cut -d: -f1) 
sed -i ${line}d ${XML_FILE}
MONTHS="05 11"
for Y in $(seq 1994 2023); do
    for M in ${MONTHS}; do 
        text="<cycledef group='"gefs"'>${Y}${M}010000 ${Y}${M}010000 24:00:00</cycledef>"
        sed -i "${line} i   ${text}" ${XML_FILE}
        line=$(( line + 1))
    done
done
