#!/bin/sh


dtg=20171004
cd /lfs/h2/emc/gefstemp/Bing.Fu/ep5ic

files=""
ic=$(find -L ./ice/ -name *${dtg}*) && files="${files} ${ic}"
ic=$(find -L ./ocn/ -name *${dtg}*) && files="${files} ${ic}"
ic=$(find -L ./wav/ -name *${dtg}*) && files="${files} ${ic}"
ic=$(find -L ./gfs/aero/ -name *${dtg}*) && files="${files} ${ic}"

for f in ${files}; do
    echo ${f}
    mkdir -p ${NPB_WORKDIR}/TEMP/${dtg}
    cp -r ${f} ${NPB_WORKDIR}/TEMP/${dtg}
done

#htar -cvf /NCEPDEV/emc-marine/1year/Neil.Barton/EP5IC_${dtg}.tar ${files}


