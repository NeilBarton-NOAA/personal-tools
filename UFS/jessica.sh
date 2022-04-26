APP=S2SW
PSLOT=test03
BASEDIR=/work/noaa/marine/jmeixner/p8b
CONFIGDIR=$BASEDIR/global-workflow/parm/config
IDATE=2013040100
EDATE=2013040100
RES=384
GFS_CYC=1
COMROT=$BASEDIR/$PSLOT/COMROOT
EXPDIR=$BASEDIR/$PSLOT/EXPDIR
ICSDIR=$BASEDIR/$PSLOT/ICDIR/${PSLOT}


#echo "Hera modules:"
#echo "module use -a /contrib/anaconda/modulefiles"
#echo "module load anaconda/anaconda3-5.3.1"
#echo "module load rocoto/1.3.3"

echo "Orion modules:"
echo "module load python/3.7.5"
echo "module load contrib"
echo "module load rocoto/1.3.3"

#echo " "
#echo "Set up script withOUT aero:"
#echo ./setup_expt.py forecast-only --app $APP --pslot $PSLOT --configdir $CONFIGDIR --idate $IDATE --edate $EDATE --res $RES --gfs_cyc $GFS_CYC --comrot $COMROT --expdir $EXPDIR --icsdir $ICSDIR

echo " "
echo "Set up script with aero:"
echo ./setup_expt.py forecast-only --app $APP --aerosols --pslot $PSLOT --configdir $CONFIGDIR --idate $IDATE --edate $EDATE --res $RES --gfs_cyc $GFS_CYC --comrot $COMROT --expdir $EXPDIR --icsdir $ICSDIR


echo " "
echo "setup workflow after any changes:"
echo ./setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT

echo " " 
echo "crontab:" 
echo $EXPDIR/$PSLOT/$PSLOT.crontab



