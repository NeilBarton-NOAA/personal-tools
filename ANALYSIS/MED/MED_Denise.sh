#!/bin/sh
set -u
file_replay=/scratch2/NCEPDEV/stmp3/Neil.Barton/ICs/2017100503/TEST_MED.nc
file_dev=/scratch2/NCEPDEV/stmp3/Neil.Barton/ufs.cpld.cpl.r.2013-04-01-21600.nc

ncrename -v atmImp_Faxa_lat,atmImp_Faxa_evap ${file_replay}
ncap2 -s 'atmImp_Faxa_evap=atmImp_Faxa_evap*(-1.0/2.501E+06)' ${file_replay}
ncap2 -s 'atmImp_Faxa_sen=atmImp_Faxa_sen*(-1.0)' ${file_replay}
ncap2 -s 'atmImp_Faxa_taux=atmImp_Faxa_taux*(-1.0)' ${file_replay}
ncap2 -s 'atmImp_Faxa_tauy=atmImp_Faxa_tauy*(-1.0)' ${file_replay}
#append the ocean albedo fields. Since they get reset to 0.06 in the next step, the date of the source arrays don't matter, only that they are the right resolution. We don't need to worry about the accum ocean albedo arrays since they're not needed on restart.

#ncks -A -v MedOcnAlb_o_So_anidf  med.restart.760e0025.nc ${file_replay}
#ncks -A -v MedOcnAlb_o_So_anidr  med.restart.760e0025.nc ${file_replay}
#ncks -A -v MedOcnAlb_o_So_avsdf  med.restart.760e0025.nc ${file_replay}
#ncks -A -v MedOcnAlb_o_So_avsdr  med.restart.760e0025.nc ${file_replay}

# reset albedos to 0.06
#ncap2 -s 'MedOcnAlb_o_So_avsdr=0.06' ${file_replay}
#ncap2 -s 'MedOcnAlb_o_So_avsdf=0.06' ${file_replay}
#ncap2 -s 'MedOcnAlb_o_So_anidr=0.06' ${file_replay}
#ncap2 -s 'MedOcnAlb_o_So_anidf=0.06' ${file_replay}


############################################################
############################################################
############################################################
#This is the set of NCO commands I used. 
#Here, 16277fa6 refers to the replay hash, 
#and 760e0025 is the current dev hash. 
#The med.restart.16277fa6.nc is what I am using to restart the model using 760e0025 code.
#
#ncrename -v atmImp_Faxa_lat,atmImp_Faxa_evap med.restart.16277fa6.nc
#ncap2 -s 'atmImp_Faxa_evap=atmImp_Faxa_evap*(-1.0/2.501E+06)' med.restart.16277fa6.nc
#ncap2 -s 'atmImp_Faxa_sen=atmImp_Faxa_sen*(-1.0)' med.restart.16277fa6.nc
#ncap2 -s 'atmImp_Faxa_taux=atmImp_Faxa_taux*(-1.0)' med.restart.16277fa6.nc
#ncap2 -s 'atmImp_Faxa_tauy=atmImp_Faxa_tauy*(-1.0)' med.restart.16277fa6.nc
##append the ocean albedo fields. Since they get reset to 0.06 in the next step, the date of the source arrays don't matter, only that they are the right resolution. We don't need to worry about the accum ocean albedo arrays since they're not needed on restart.
#
#ncks -A -v MedOcnAlb_o_So_anidf  med.restart.760e0025.nc  med.restart.16277fa6.nc
#ncks -A -v MedOcnAlb_o_So_anidr  med.restart.760e0025.nc  med.restart.16277fa6.nc
#ncks -A -v MedOcnAlb_o_So_avsdf  med.restart.760e0025.nc  med.restart.16277fa6.nc
#ncks -A -v MedOcnAlb_o_So_avsdr  med.restart.760e0025.nc  med.restart.16277fa6.nc
#
## reset albedos to 0.06
#ncap2 -s 'MedOcnAlb_o_So_avsdr=0.06'  med.restart.16277fa6.nc
#ncap2 -s 'MedOcnAlb_o_So_avsdf=0.06'  med.restart.16277fa6.nc
#ncap2 -s 'MedOcnAlb_o_So_anidr=0.06'  med.restart.16277fa6.nc
#ncap2 -s 'MedOcnAlb_o_So_anidf=0.06'  med.restart.16277fa6.nc
#
#
#If used the med.restart.16277fa6.nc to restart the model using the 16277fa6 ATM, MOM, ICE restarts, and this is the tmpsfc difference on tile 3 12 hours after restart:
