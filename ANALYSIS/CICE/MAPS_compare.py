#!/usr/bin/env python3 
####################################################################################
import argparse
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import numpy as np
import os
import shutil
import sys
import xarray as xr
sys.path.append('/home/Neil.Barton/TOOLS')
import PYTHON_TOOLS as npb

################################################
f='iceh_inst.2017-10-20-00000.nc'
dir1='/scratch2/NCEPDEV/stmp3/Neil.Barton/RUNS/ICE_TESTING/DEFAULT_ENS0/history/'
dir2='/scratch2/NCEPDEV/stmp3/Neil.Barton/RUNS/ICE_TESTING/DEFAULT_ENS9/history/'
title = 'Default ENS0 Minus Default ENS5: 2017-10-20 '
fig_name = 'DefaultENS0_minus_DefaultENS5.png'
#dir2='/scratch2/NCEPDEV/stmp3/Neil.Barton/RUNS/ICE_TESTING/TEST_EDGE_0.15_ENS9/history/'
#title = 'Default ENS0 Minus Edge ENS9: 2017-10-20 '
#fig_name = 'DefaultENS0_minus_EDGE015ENS9.png'

################################################
dat1 = xr.open_dataset(dir1 + f)
dat2 = xr.open_dataset(dir2 + f)

################################################
fig = plt.figure()
ax1 = fig.add_subplot(2,2,1, projection=ccrs.NorthPolarStereo())
ax1 = npb.base_maps.Arctic(ax1, labels = False)
ax1 = npb.base_maps.add_features(ax1)
ax2 = fig.add_subplot(2,2,2, projection=ccrs.SouthPolarStereo())
ax2 = npb.base_maps.Antarctic(ax2, labels = False)
ax2 = npb.base_maps.add_features(ax2)
ax3 = fig.add_subplot(2,2,3, projection=ccrs.NorthPolarStereo())
ax3 = npb.base_maps.Arctic(ax3, labels = False)
ax3 = npb.base_maps.add_features(ax3)
ax4 = fig.add_subplot(2,2,4, projection=ccrs.SouthPolarStereo())
ax4 = npb.base_maps.Antarctic(ax4, labels = False)
ax4 = npb.base_maps.add_features(ax4)
cmap = plt.get_cmap('RdBu_r')
d = dat1['aice_h'][0] - dat2['aice_h'][0]
area = xr.open_dataset(os.environ['NPB_WORKDIR'] + '/ICs/cice_area.nc') # need lat/lons
# total concentration difference
print(np.min(d).values, np.max(d).values)
v_min = -1.0
v_max = 1.0
cf = ax1.pcolormesh(area['TLON'].values, area['TLAT'].values, d, cmap = cmap, \
    vmin = v_min, vmax = v_max, transform = ccrs.PlateCarree())
cf = ax2.pcolormesh(area['TLON'].values, area['TLAT'].values, d, cmap = cmap, \
    vmin = v_min, vmax = v_max, transform = ccrs.PlateCarree())
ax1.text(270, 50, 'Ice Concentration', rotation = 'vertical', \
    ha = 'center', va = 'center', transform = ccrs.PlateCarree())
############
d = np.where(dat1['aice_h'][0] > 0.15, 1.0, 0.0) - np.where(dat2['aice_h'][0] > 0.15, 1.0, 0.0)
print(np.min(d), np.max(d))
cf = ax3.pcolormesh(area['TLON'].values, area['TLAT'].values, d, cmap = cmap, \
    vmin = v_min, vmax = v_max, transform = ccrs.PlateCarree())
cf = ax4.pcolormesh(area['TLON'].values, area['TLAT'].values, d, cmap = cmap, \
    vmin = v_min, vmax = v_max, transform = ccrs.PlateCarree())
ax3.text(270, 50, 'Ice Mask', rotation = 'vertical', \
    ha = 'center', va = 'center', transform = ccrs.PlateCarree())
cax = fig.add_axes([0.22, 0.05, 0.6, 0.03])
fig.colorbar(cf, cax = cax, orientation = 'horizontal')
# title and save
fig.suptitle(title, y = 0.95)
plt.savefig(fig_name, dpi = 600)
print('SAVED: ', fig_name)
plt.show()
plt.close()

