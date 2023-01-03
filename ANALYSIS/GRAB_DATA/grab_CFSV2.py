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
import numpy as np
import xarray as xr
import argparse
import glob
parser = argparse.ArgumentParser( description=
    "This cats netcdf files")

#parser.add_argument('-f', '--files', action='store',  nargs = '+', help='files for analysis')

#args = parser.parse_args()
#files = args.files
#var='ICE_surface'
files = glob.glob('/scratch1/NCEPDEV/climate/Lydia.B.Stefanova/Models/cfs_v2/t126/netcdf/icecon*nc')
files.sort()
def postproc(ds):
    t = ds['time'][0].values - np.timedelta64(6,'h')
    ds['time'] = ((ds['time'] - ds['time'][0]) / 3600000000000.0).astype('float32') / 24.0
    ds = ds.rename_dims({'time': 'tau'})
    ds = ds.rename_vars({'time': 'tau'})
    ds = ds.expand_dims(time = [t])
    return ds

data_list = []
for f in files:
    print(f)
    ds = xr.open_dataset(f)
    data_list.append(postproc(ds))

ds = xr.concat(data_list, dim = 'time')
save_file = '/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/CFSV2_icecon.nc'
ds.to_netcdf(save_file)
#print(ds)
#print(data_list)
# load data
#save_file = os.path.dirname(files[0]) + '/' + os.path.basename(files[0]).split('_')[0] + '_' + var + '.nc'
#ds = xr.open_mfdataset(files)
#ds['area'] = ds['tarea'].isel(tau = 0 , time = 0)
#new_ds = ds[var]
#new_ds['area'] = (ds['area'].dims, ds['area'].values)
#print('writting:', save_file)
#new_ds.to_netcdf(save_file)
#print('wrote:', save_file)


