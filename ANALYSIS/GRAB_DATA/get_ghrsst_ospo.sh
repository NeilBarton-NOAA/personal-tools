#!/bin/bash
set -x
start_date=20240709
end_date=20240709
date=$start_date
while [ $date -le $end_date ]; do
    year=`echo $date |cut -c 1-4`
    month=`echo $date |cut -c 5-6`
    day=`echo $date |cut -c 7-8`
    wget https://www.star.nesdis.noaa.gov/thredds/fileServer/Blended/SST5km/Night/GHRSSTOSPO/${year}/${year}${month}${day}000000-OSPO-L4_GHRSST-SSTfnd-Geo_Polar_Blended_Night-GLOB-v02.0-fv01.0.nc
    mv ${year}${month}${day}000000-OSPO-L4_GHRSST-SSTfnd-Geo_Polar_Blended_Night-GLOB-v02.0-fv01.0.nc ${date}_OSPO_L4_GHRSST.nc
    tdate=`$NDATE +24 ${date}00`
    date=`echo $tdate |cut -c 1-8`
done
