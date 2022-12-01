#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   compare UFS data sets
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
#from glob import glob
#import matplotlib.pylab as plt
import numpy as np
import xarray as xr
import os
import sys
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + '/PYTHON_TOOLS')
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + '/UFS_OUTPUT_TOOLS')
import PYTHON_TOOLS as npb
import UFS_OUTPUT_TOOLS as ufs

f = '/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8T/ICEC.nc'
var = 'ICEC_surface'
ds = xr.open_dataset(f)
dat = ds[var]
dat = dat[:,:,dat.latitude > 60, :]

test = np.arange(0,dat['time'].size,1)
tau, lat, lon, time = np.meshgrid(dat['tau'].values, dat['latitude'].values, dat['longitude'].values, dat['time'].values)
#tt = np.zeros(dat.shape)

print(tt.shape)
print(test.shape)
#print(dat)
#tt = np.zeros
#dat = dat.assign(test = (['time'], test))
#print(dat)
#dat = dat.expand_dims('test')
#print(dat)
