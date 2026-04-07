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
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path
import sys, glob
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from PIL import Image
var='SST'
print(var)
dir1="/scratch4/NCEPDEV/stmp/Neil.Barton/RUNS/COMROOT/SFSBETA1.1_GFSv17ICs"
dir2="/scratch3/NCEPDEV/global/Yangxing.Zheng/SFS_NRT_C192mx025_20260301"
temp_f="/scratch4/NCEPDEV/stmp/Neil.Barton/sfs_ocean.zarr"
my_dir = Path(temp_f)
# model data

def get_thickness(z_l):
    dz = np.diff(z_l)
    z_i = [0]
    # Intermediate interfaces are mid-way between centers
    for i in range(len(dz)):
        z_i.append(z_l[i] + dz[i]/2)
    # The last interface is extrapolated: 
    # (Last center + distance from the previous interface to that center)
    last_gap = z_l[-1] - z_i[-1]
    z_i.append(z_l[-1] + last_gap)
    z_i = np.array(z_i)
    return np.diff(z_i)

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
        d="/sfs.20260301/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocnheat*monthly_avg*nc"
        files = glob.glob(dir1 + d)
        dd = xr.open_mfdataset(files)
        ds['ocnheat'] = (ds['SST'].dims, dd['ocnheat'].values)
        d="/sfs.20260301/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.dt20*monthly_avg*nc"
        files = glob.glob(dir1 + d)
        dd = xr.open_mfdataset(files)
        ds['dt20c'] = (ds['SST'].dims, dd['dt20c'].values)
        ds_gfs.append(ds.expand_dims({'member' : [mem]}))
        del ds
        ########################
        # cpc ic runs
        d="/sfs.20260301/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocean*monthly_avg*nc"
        files = glob.glob(dir2 + d)
        ds = xr.open_mfdataset(files)
        d="/sfs.20260301/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocnheat*monthly_avg*nc"
        files = glob.glob(dir2 + d)
        dd = xr.open_mfdataset(files)
        ds['ocnheat'] = (ds['SST'].dims, dd['ocnheat'].values)
        d="/sfs.20260301/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.dt20*monthly_avg*nc"
        files = glob.glob(dir2 + d)
        dd = xr.open_mfdataset(files)
        ds['dt20c'] = (ds['SST'].dims, dd['dt20c'].values)
        ds_cpc.append(ds.expand_dims({'member' : [mem]}))
        del ds
    ds_gfs = xr.concat(ds_gfs, dim = 'member')
    ds_gfs = ds_gfs.expand_dims({'experiment': ['gfs_ics']})
    ds_cpc = xr.concat(ds_cpc, dim = 'member')
    ds_cpc = ds_cpc.expand_dims({'experiment': ['cpc_ics']})
    ds = xr.concat([ds_cpc, ds_gfs], dim = 'experiment')
    ds.to_zarr(temp_f, consolidated=True)
print(ds)
if var == 'SSS':
    ds[var] = ds['so'].isel(z_l = 0 )
if var == 'salinity_vert_ave':
    h = xr.DataArray(get_thickness(ds['z_l']), coords={'z_l': ds.z_l}, dims=['z_l'])
    salt = ds['so'] * h
    salt_w = salt.sum(dim='z_l') / h.sum(dim='z_l')
    ds[var] = salt_w.where(ds['SST'].notnull())

########################
# spatial plots
exps = ['gfs_ics', 'cpc_ics', 'gfs_ics minus cpc_ics']
c_maps = ['magma', 'magma', 'RdBu_r']
if var == 'SST':
    limits = [(0, 28), (0, 28), (-3, 3)]
if var == 'SSS':
    limits = [(25, 40), (25, 40), (-3, 3)]
if var == 'salinity_vert_ave':
    print(ds[var].min().values, ds[var].max().values)
    limits = [(25, 35), (25, 35), (-1, 1)]
if var == 'dt20c':
    print(ds[var].min().values, ds[var].max().values)
    limits = [(100, 200), (100, 200), (-50, 50)]
if var == 'ocnheat':
    print(ds[var].min().values/1e8, ds[var].max().values/1e8)
    limits = [(100e8, 300e8), (100e8, 300e8), (-50e8, 50e8)]
if var == 'SSH':
    print(ds[var].min().values/1e8, ds[var].max().values/1e8)
    limits = [(-2.0, 1.0), (-2., 1.), (-0.5, 0.5)]
gif_files=[]
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
            levels = 16,
            cbar_kwargs={'orientation': 'horizontal', 'pad': 0.05}
        )
        # Add map features
        ax.coastlines()
        ax.add_feature(cfeature.BORDERS, linestyle=':')
        ax.set_global() # Ensures the whole world is shown
        ax.set_title(str(t.dt.year.values) + '-' + str(t.dt.month.values).zfill(2) + ': ' + exps[i])
    plt.tight_layout()
    name = var + '_' + str(t.dt.year.values) + '-' + str(t.dt.month.values).zfill(2) + '.png'
    gif_files.append(name)
    #plt.show(); exit(1)
    plt.savefig(name)
    plt.close()
frames = [Image.open(image) for image in gif_files]
frames[0].save(var + "_maps.gif", save_all=True, append_images=frames[1:], duration=500, loop=0)
    

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
############
weights = np.cos(np.deg2rad(nino34.latitude))
weights.name = "weights"
dat = nino34[var].weighted(weights).mean(("latitude", "longitude"))
#dat = nino34[var].mean(('latitude', 'longitude'))
plt.figure()
colors = ['blue', 'green']
for i, n in enumerate(['gfs_ics', 'cpc_ics']):
    mean = dat.sel(experiment = n).mean(dim = 'member') 
    pd = dat.sel(experiment = n).quantile(0.25, dim = 'member') 
    pu = dat.sel(experiment = n).quantile(0.75, dim = 'member') 
    plt.plot(mean.time, mean, color=colors[i], label = n)
    plt.fill_between(mean.time, pd, pu, color=colors[i], alpha=0.2)
plt.legend()
plt.ylim([27.7, 29.2])
plt.title('Nino 3.4')
plt.savefig(var + '_nino34.png')
print('SCRIPT FINISHED')


