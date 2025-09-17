#!/bin/bash
set -x
start_date=20221109
end_date=20221109
date=$start_date
while [ $date -le $end_date ]; do
    year=`echo $date |cut -c 1-4`
    month=`echo $date |cut -c 5-6`
    day=`echo $date |cut -c 7-8`
    for hem in nh sh ; do
        wget ftp://osisaf.met.no/archive/ice/conc/${year}/${month}/ice_conc_${hem}_polstere-100_multi_${year}${month}${day}1200.nc
    done
    tdate=`$NDATE +24 ${date}00`
    date=`echo $tdate |cut -c 1-8`
done
