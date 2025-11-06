#!/usr/bin/env python3
import argparse
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import os
import netCDF4 as nc
import numpy as np
import sys
import xarray as xr
sys.path.append(os.environ.get('HOME') + '/TOOLS')
import PYTHON_TOOLS as npb

hour = 91*24
f = 'sfs.ice.t00z.24hr_avg.f' + str(hour) + '.nc'
var = 'aice_h'
dir1 = '/work/noaa/marine/nbarton/RUNS/COMROOT/SFSbeta0.1_C192mx025_S2S_REPLAY_ICS/sfs.20231101/00/mem000/model/ice/history'
dir2 = '/work/noaa/marine/nbarton/RUNS/COMROOT/SFSbeta0.1_C192mx025_S2S_REPLAY_ICS_linear/sfs.20231101/00/mem000/model/ice/history'

ds1 = xr.open_dataset(dir1 + '/' + f)
#for v in ds1.variables:
#    print(v)
#exit(1)
ds2 = xr.open_dataset(dir2 + '/' + f)
diff = ds1[var].squeeze()
#diff = ds1[var].squeeze() - ds2[var].squeeze()
if var == 'aice_h':
    v_max = 1.0
elif var == 'hi_h':
    v_max = 5.0
else:
    print(var)
    print(diff.min().values, diff.max().values)
    v_max = max(abs(diff.min().values), diff.max().values)
v_min = 0
#v_min = v_max * -1.0
date = np.datetime_as_string(ds1['time'].squeeze().values + np.timedelta64(hour, 'h'), unit='D')
#text = 'Control Minus Linear: Day ' + str(int(hour/24)) + ' (' + date + ')'
text = 'Control: Day ' + str(int(hour/24)) + ' (' + date + ')'
# NH Plot
fig = plt.figure()
ax = fig.add_subplot(1,1,1, projection=ccrs.NorthPolarStereo())
ax = npb.base_maps.Arctic(ax, labels = False)
ax = npb.base_maps.add_features(ax)
cf = ax.pcolormesh(ds1['TLON'], ds1['TLAT'], diff, vmin = v_min, vmax = v_max, transform = ccrs.PlateCarree())
plt.colorbar(cf, shrink = 0.5)
ax.set_title(text)
fig_name = 'NH' + var + text.replace(' ','').replace(':','_') + '.png'
plt.savefig(fig_name)
# SH Plot
fig = plt.figure()
ax = fig.add_subplot(1,1,1, projection=ccrs.SouthPolarStereo())
ax = npb.base_maps.Antarctic(ax, labels = True)
ax = npb.base_maps.add_features(ax)
cf = ax.pcolormesh(ds1['TLON'], ds1['TLAT'], diff, vmin = v_min, vmax = v_max, transform = ccrs.PlateCarree())
plt.colorbar(cf, shrink = 0.5)
ax.set_title(text)
fig_name = 'SH' + var + text.replace(' ','').replace(':','_') + '.png'
plt.savefig(fig_name)

#plt.imshow(diff, origin = 'lower'); plt.colorbar()
#plt.show()
