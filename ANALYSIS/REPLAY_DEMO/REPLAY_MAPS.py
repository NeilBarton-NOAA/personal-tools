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
'/scratch2/NCEPDEV/stmp3/Neil.Barton/REPLAY_DEMO/CTL',
'/scratch2/NCEPDEV/stmp3/Neil.Barton/REPLAY_DEMO/RPL'
]
var = 'aice_d'
   
CTL = xr.open_mfdataset( dirs[0] + '/' + var + '*.nc')
RPL = xr.open_mfdataset( dirs[1] + '/' + var + '*.nc')

NH_ICE, SH_ICE = npb.iceobs.get_iceobs() 
EXT = npb.iceobs.get_extentobs_NASA()

if (CTL['time'] == RPL['time']).any() == False:
    print('times do not match')
    exit(1)

# plot season average of day 0, 1, 5, 20 forecast hours
attrs = { 'MIN': 0.0, 'MAX': 1.0, 'DMIN': -1.0, 'DMAX': 1.0}
for tau in [0,1,5,20]: 
    t_array = npb.timetools.time_plus_tau(CTL['time'].values, tau*24)
    OBS = []
    OBS.append(NH_ICE['ice_con'].sel(time = t_array).mean(dim = 'time'))
    OBS.append(SH_ICE['ice_con'].sel(time = t_array).mean(dim = 'time'))
    C = CTL[var].sel(tau = tau*24).mean(dim = 'time')
    R = RPL[var].sel(tau = tau*24).mean(dim = 'time')
    C = C.assign_attrs(attrs)
    C = C.assign_attrs({'test_name' : 'Control'})
    C = C.assign_attrs({'title' : 'Sea Ice Concentrations: Forecast Day ' + str(tau)})
    C = C.assign_attrs({'save_dir' : '/scratch2/NCEPDEV/stmp3/Neil.Barton/FIGURES'})
    R = R.assign_attrs(attrs)
    R = R.assign_attrs({'test_name' : 'Replay'})
    for i, d in enumerate(['Arctic', 'Antarctic']):
        npb.maps.difference(C, R, OBS[i], domain = d)

