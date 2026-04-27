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
var='SST'
dir1="/scratch4/NCEPDEV/stmp/Neil.Barton/RUNS/COMROOT/SFSBETA1.1_GFSv17ICs"
dir2="/scratch3/NCEPDEV/global/Yangxing.Zheng/SFS_NRT_C192mx025_20260301"
temp_f="/scratch4/NCEPDEV/stmp/Neil.Barton/sfs.zarr"
my_dir = Path(temp_f)
# model data

if my_dir.exists():
    ds = xr.open_dataset(temp_f)
else:
    ds_gfs, ds_cpc = [], []
    for mem in range(31):
        print("member: ", mem)
        d="/sfs.20260301/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocean*monthly_avg*nc"
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
if var == 'SSS':
    ds['SSS'] = ds['so'].isel(z_l = 0 )
########################
# spatial plots
exps = ['gfs_ics', 'cpc_ics', 'gfs_ics minus cpc_ics']
c_maps = ['magma', 'magma', 'RdBu_r']
if var == 'SST':
    limits = [(0, 28), (0, 28), (-3, 3)]
if var == 'SSS':
    limits = [(25, 40), (25, 40), (-3, 3)]

for t in ds.time:
    print(t.values)
    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(18, 5), subplot_kw={'projection': ccrs.Robinson()})
    for i, ax in enumerate(axes):
        # Select the data (example: first 3 time steps)
        if i == 0:
            dat = ds[var].sel(time = t, experiment = 'gfs_ics').mean(dim = 'member')
        if i == 1:
            dat = ds[var].sel(time = t, experiment = 'cpc_ics').mean(dim = 'member')
        if i == 2:
            dat1 = ds[var].sel(time = t, experiment = 'gfs_ics').mean(dim = 'member')
            dat2 = ds[var].sel(time = t, experiment = 'cpc_ics').mean(dim = 'member')
            dat = dat1 - dat2
        # Plot using xarray's built-in plotting (transform is CRITICAL here)
        v_min, v_max = limits[i]
        dat.plot(
            ax=ax, 
            transform=ccrs.PlateCarree(), # Data is usually lat/lon (PlateCarree)
            cmap = c_maps[i],
            vmin = v_min,
            vmax = v_max,
            cbar_kwargs={'orientation': 'horizontal', 'pad': 0.05}
        )
        # Add map features
        ax.coastlines()
        ax.add_feature(cfeature.BORDERS, linestyle=':')
        ax.set_global() # Ensures the whole world is shown
        ax.set_title(str(t.dt.year.values) + '-' + str(t.dt.month.values).zfill(2) + ': ' + exps[i])
    plt.tight_layout()
    name = var + '_' + str(t.dt.year.values) + '-' + str(t.dt.month.values).zfill(2) + '.png'
    print(name)
    plt.savefig(name)
    


####################################
# globe
weights = np.cos(np.deg2rad(ds.latitude))
weights.name = "weights"
dat = ds[var].weighted(weights).mean(("latitude", "longitude"))
plt.figure()
colors = ['blue', 'green']
for i, n in enumerate(['gfs_ics', 'cpc_ics']):
    mean = dat.sel(experiment = n).mean(dim = 'member') 
    pd = dat.sel(experiment = n).quantile(0.25, dim = 'member') 
    pu = dat.sel(experiment = n).quantile(0.75, dim = 'member') 
    plt.plot(mean.time, mean, color=colors[i], label = n)
    plt.fill_between( mean.time, pd, pu, color=colors[i], alpha=0.2)
plt.legend()
plt.title('Global')
plt.savefig(var + '_global.png')

####################################
# calc nino3.4
nino34 = ds.sel(latitude=slice(-5, 5), longitude=slice(190, 240))
weights = np.cos(np.deg2rad(nino34.latitude))
weights.name = "weights"
dat = nino34[var].weighted(weights).mean(("latitude", "longitude"))
plt.figure()
colors = ['blue', 'green']
for i, n in enumerate(['gfs_ics', 'cpc_ics']):
    mean = dat.sel(experiment = n).mean(dim = 'member') 
    pd = dat.sel(experiment = n).quantile(0.25, dim = 'member') 
    pu = dat.sel(experiment = n).quantile(0.75, dim = 'member') 
    plt.plot(mean.time, mean, color=colors[i], label = n)
    plt.fill_between( mean.time, pd, pu, color=colors[i], alpha=0.2)
plt.legend()
plt.title('Nino 3.4')
plt.savefig(var + '_nino34.png')



