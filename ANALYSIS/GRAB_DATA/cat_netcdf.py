#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   compare UFS data sets
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
#from glob import glob
#import matplotlib.pylab as plt
#import numpy as np
import os
import sys
import xarray as xr
import argparse

parser = argparse.ArgumentParser( description=
    "This cats netcdf files")

parser.add_argument('-f', '--files', action='store',  nargs = '+', help='files for analysis')

args = parser.parse_args()
files = args.files
var='aice_h'
# load data
save_file = os.path.dirname(files[0]) + '/' + os.path.basename(files[0]).split('_')[0] + '_' + var + '.nc'
ds = xr.open_mfdataset(files)
ds['area'] = ds['tarea'].isel(tau = 0 , time = 0)
new_ds = ds[var]
new_ds['area'] = (ds['area'].dims, ds['area'].values)
print('writting:', save_file)
new_ds.to_netcdf(save_file)
print('wrote:', save_file)


