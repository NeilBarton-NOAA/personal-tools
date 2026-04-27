#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   quick plot netcdf data
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
# https://xesmf.readthedocs.io/en/latest/notebooks/Masking.html
########################
import xarray as xr
import xesmf as xe
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import sys, glob
import cartopy.crs as ccrs
import cartopy.feature as cfeature
ymd="20260401"
dir1="/scratch4/NCEPDEV/stmp/Neil.Barton/RUNS/COMROOT/beta1.1_GFS_ICs"
dir2="/scratch3/NCEPDEV/global/Yangxing.Zheng/SFS_NRT_C192mx025"
temp_f="/scratch4/NCEPDEV/stmp/Neil.Barton/sfs_ice.zarr"
my_dir = Path(temp_f)
# model data

if my_dir.exists():
    ds = xr.open_dataset(temp_f)
else:
    ds_gfs, ds_cpc = [], []
    for mem in range(31):
        print("member: ", mem)
        d="/sfs." + ymd + "/00/mem" + str(mem).zfill(3) + "/products/ice/netcdf/native/sfs.*monthly_avg*nc"
        # gfs ic runs
        files = glob.glob(dir1 + d)
        ds = xr.open_mfdataset(files)
        ds_gfs.append(ds.expand_dims({'member' : [mem]}))
        # cpc ic runs
        files = glob.glob(dir2 + d)
        ds = xr.open_mfdataset(files)
        ds_cpc.append(ds.expand_dims({'member' : [mem]}))
    ds_gfs = xr.concat(ds_gfs, dim = 'member')
    ds_gfs = ds_gfs.expand_dims({'experiment': ['gfs_ics']})
    ds_cpc = xr.concat(ds_cpc, dim = 'member')
    ds_cpc = ds_cpc.expand_dims({'experiment': ['cpc_ics']})
    ds = xr.concat([ds_cpc, ds_gfs], dim = 'experiment')
    ds.to_zarr(temp_f, consolidated=True)

print(ds)

NH_extent = ds['cell_area'].where((ds['TLAT'] > 20) & (ds['aice_h'] >= 0.15)).sum(dim = ['nj', 'ni']) / 1e12
SH_extent = ds['cell_area'].where((ds['TLAT'] < -20) & (ds['aice_h'] >= 0.15)).sum(dim = ['nj', 'ni']) / 1e12
dat = NH_extent
colors = ['blue', 'green']
for i, n in enumerate(['gfs_ics', 'cpc_ics']):
    mean = dat.sel(experiment = n).mean(dim = 'member') 
    pd = dat.sel(experiment = n).quantile(0.25, dim = 'member') 
    pu = dat.sel(experiment = n).quantile(0.75, dim = 'member') 
    plt.plot(mean.time, mean, color=colors[i], label = n)
    plt.fill_between( mean.time, pd, pu, color=colors[i], alpha=0.2)
plt.legend()
plt.title('NH Extent')
plt.savefig('NH_seaiceextent.png')
plt.close()

dat = SH_extent
colors = ['blue', 'green']
for i, n in enumerate(['gfs_ics', 'cpc_ics']):
    mean = dat.sel(experiment = n).mean(dim = 'member') 
    pd = dat.sel(experiment = n).quantile(0.25, dim = 'member') 
    pu = dat.sel(experiment = n).quantile(0.75, dim = 'member') 
    plt.plot(mean.time, mean, color=colors[i], label = n)
    plt.fill_between( mean.time, pd, pu, color=colors[i], alpha=0.2)
plt.legend()
plt.title('SH Extent')
plt.savefig('SH_seaiceextent.png')
plt.close()

exit(1)
