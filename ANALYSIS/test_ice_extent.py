#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   quick plot netcdf data
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
# check platform
#import platform
#if 'hfe' in platform.uname()[1]:
#    print('only run on an interactive node')
#    print(platform.uname()[1])
#    exit(1)
############
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
f1 = '/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/GFSRETRO/interp_obs_grids_aice_2023041800.nc'
f2 = '/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/OBS/ice_concentration/noaa_cdr/north/seaice_conc_daily_nh_2023_v04r00.nc'

dat = xr.open_dataset(f1)
model = dat['aiceNH25_binary'][0,0].values

obs = xr.open_dataset(f2)
print(obs)
ob = obs['cdr_seaice_conc'].sel(tdim = 108)
ob = ob.where(ob < 2, 0)
ob = ob.where(ob < 0.15,1,0).values
diff = model - ob

fig = plt.figure(figsize=(8, 6))
ax = fig.add_subplot(1,1,1, projection = ccrs.NorthPolarStereo())
ax = npb.base_maps.Arctic(ax, labels = False)
t_lon, t_lat = 180.0, 53.0
dx = dy = 25000
x = np.arange(-3850000, +3750000, +dx)
y = np.arange(+5850000, -5350000, -dy)
kw = dict(central_latitude=90, central_longitude=-45, true_scale_latitude=70)
#x, y, kw = npb.maps.getICEdomain('north')
im = ax.pcolormesh(x, y, diff, transform = ccrs.Stereographic(**kw))
ax = npb.base_maps.add_features(ax)
#plt.colorbar()
plt.show()
#plt.imshow(model - ob); plt.colorbar(); plt.show()
