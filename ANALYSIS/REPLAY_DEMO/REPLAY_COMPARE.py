#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   compare REPLAY data sets
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
# check platform
import platform
if 'hfe' in platform.uname()[1]:
    print('only run on an interactive node')
    print(platform.uname()[1])
    exit(1)
########################
import os
import sys
import xarray as xr
sys.path.append('/home/Neil.Barton/TOOLS')
sys.path.append(os.path.dirname(os.path.realpath(__file__)) )
import PYTHON_TOOLS as npb

dirs = [
'/scratch2/NCEPDEV/stmp3/Neil.Barton/DIAG/REPLAY_DEMO/CTL',
'/scratch2/NCEPDEV/stmp3/Neil.Barton/DIAG/REPLAY_DEMO/RPL'
]
var = 'aice_d'
   
CTL = xr.open_mfdataset( dirs[0] + '/' + var + '*.nc')
RPL = xr.open_mfdataset( dirs[1] + '/' + var + '*.nc')

NH_ICE, SH_ICE = npb.iceobs.get_iceobs() 
EXT = npb.iceobs.get_extentobs_NASA()

if (CTL['time'] == RPL['time']).any() == False:
    print('times do not match')
    exit(1)

## plot month and sea ice extent 
CTL = CTL.assign_attrs({'extent_file' : dirs[0] + '/ice_extent.nc'})
CTL = npb.iceobs.calc_extent(CTL)
RPL = RPL.assign_attrs({'extent_file' : dirs[1] + '/ice_extent.nc'})
CTL = CTL.assign_attrs({'test_name' : 'Control / Marine GDAS'})
CTL = CTL.assign_attrs({'save_dir' : '/scratch2/NCEPDEV/stmp3/Neil.Barton/FIGURES'})
RPL = npb.iceobs.calc_extent(RPL)
RPL = RPL.assign_attrs({'test_name' : 'Replay'})
RPL = RPL.assign_attrs({'save_dir' : '/scratch2/NCEPDEV/stmp3/Neil.Barton/FIGURES'})
CTL['tau'] = CTL['tau'] / 24.0
RPL['tau'] = RPL['tau'] / 24.0
npb.plot.ice_extent_per_month([CTL, RPL], EXT,  var = 'NH_extent')
npb.plot.ice_extent_per_month([CTL, RPL], EXT,  var = 'SH_extent')

############
# comparison between runs
attrs = {'DMIN': -5.0, 'DMAX': 5.0}
CTL = CTL.assign_attrs(attrs)
RPL = RPL.assign_attrs(attrs)
npb.plot.ice_extent_imshowdiff(CTL, RPL, var = 'NH_extent')
attrs = {'DMIN': -9.0, 'DMAX': 9.0}
CTL = CTL.assign_attrs(attrs)
RPL = RPL.assign_attrs(attrs)
npb.plot.ice_extent_imshowdiff(CTL, RPL, var = 'SH_extent')
############
# NH comparison
attrs = {'DMIN': -4.0, 'DMAX': 4.0}
CTL = CTL.assign_attrs(attrs)
RPL = RPL.assign_attrs(attrs)
npb.plot.ice_extent_imshowdiff(CTL, EXT, var = 'NH_extent')
npb.plot.ice_extent_imshowdiff(RPL, EXT, var = 'NH_extent')
############
# SH comparison
attrs = {'DMIN': -9.0, 'DMAX': 9.0}
CTL = CTL.assign_attrs(attrs)
RPL = RPL.assign_attrs(attrs)
npb.plot.ice_extent_imshowdiff(CTL, EXT, var = 'SH_extent')
npb.plot.ice_extent_imshowdiff(RPL, EXT, var = 'SH_extent')

# plot month by tau heat map

