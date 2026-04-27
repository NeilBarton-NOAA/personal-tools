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
import matplotlib.ticker as mticker
from pathlib import Path
import sys, glob
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from PIL import Image
# SST SST ocnheat dt20c SSS salinity_vert_ave SW
#var='ocnheat'
var = sys.argv[1] if len(sys.argv) > 1 else 'SST'
print(var)
ymd="20260401"
dir1="/scratch4/NCEPDEV/stmp/Neil.Barton/RUNS/COMROOT/beta1.1_GFS_ICs"
dir2="/scratch3/NCEPDEV/global/Yangxing.Zheng/SFS_NRT_C192mx025"
temp_f="/scratch4/NCEPDEV/stmp/Neil.Barton/sfs_ocean.zarr"
my_dir = Path(temp_f)
# model data
limits = {  'SST':                  [(0, 28), (0, 28), (-3, 3)],
            'SSS':                  [(25, 40), (25, 40), (-3, 3)],
            'SSH':                  [(-2.0, 1.0), (-2., 1.), (-0.5, 0.5)],
            'WWV':                  [(1000.0, 2000.0), (1000., 2000.), (-800., 800.)],
            'MLD_003':              [(0.0, 40.0), (0., 40.), (-50., 50.)],
            'SW':                   [(50.0, 300.0), (50., 300.), (-30., 30.)],
            'salinity_vert_ave':    [(25, 35), (25, 35), (-1, 1)],
            'dt20c':                [(100, 200), (100, 200), (-50, 50)],
            'T300':                 [(10, 30), (10, 30), (-15, 15)],
            'ocnheat':              [(10, 30), (10, 30), (-15, 15)]
         }   

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
        d="/sfs." + ymd + "/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocean*monthly_avg*nc"
        # gfs ic runs
        print(dir1 + d)
        files = glob.glob(dir1 + d)
        ds = xr.open_mfdataset(files)
        d="/sfs." + ymd + "/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocnheat*monthly_avg*nc"
        files = glob.glob(dir1 + d)
        dd = xr.open_mfdataset(files)
        ds['ocnheat'] = (ds['SST'].dims, dd['ocnheat'].values)
        d="/sfs." + ymd + "/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.dt20*monthly_avg*nc"
        files = glob.glob(dir1 + d)
        dd = xr.open_mfdataset(files)
        ds['dt20c'] = (ds['SST'].dims, dd['dt20c'].values)
        ds_gfs.append(ds.expand_dims({'member' : [mem]}))
        del ds
        ########################
        # cpc ic runs
        d="/sfs." + ymd + "/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocean*monthly_avg*nc"
        files = glob.glob(dir2 + d)
        ds = xr.open_mfdataset(files)
        d="/sfs." + ymd + "/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.ocnheat*monthly_avg*nc"
        files = glob.glob(dir2 + d)
        dd = xr.open_mfdataset(files)
        ds['ocnheat'] = (ds['SST'].dims, dd['ocnheat'].values)
        d="/sfs." + ymd + "/00/mem" + str(mem).zfill(3) + "/products/ocean/netcdf/1p00/sfs.dt20*monthly_avg*nc"
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
R = 6371000  # Radius of Earth in meters
d_lat = np.radians(1.0) # 1 degree in radians
d_lon = np.radians(1.0) # 1 degree in radians
area = (R**2) * d_lat * d_lon * np.cos(np.radians(ds['latitude']))

if var == 'SSS':
    ds[var] = ds['so'].isel(z_l = 0 )
if var == 'salinity_vert_ave':
    h = xr.DataArray(get_thickness(ds['z_l']), coords={'z_l': ds.z_l}, dims=['z_l'])
    salt = ds['so'] * h
    salt_w = salt.sum(dim='z_l') / h.sum(dim='z_l')
    ds[var] = salt_w.where(ds['SST'].notnull())
if var == 'WWV':
    mld_broadcast, area = xr.broadcast(ds['dt20c'], area)
    ds[var] = (ds['dt20c'] * area) / 1e9
if var == 'ocnheat':
    ds['ocnheat'] = ds['ocnheat'] / 1e9
if var == 'T300':
    rho0 = 1035.0
    cp = 3991.8679
    ds['h'] = xr.DataArray(get_thickness(ds['z_l']), coords={'z_l': ds.z_l}, dims=['z_l'])
    depth_bottom = ds.h.cumsum(dim='z_l')
    depth_top = depth_bottom - ds.h
    dz_300 = np.maximum(0, np.minimum(depth_bottom, 300) - depth_top)
    ohc_per_m2 = (ds.temp * dz_300 * rho0 * cp).sum(dim='z_l')
    ds[var] = ohc_per_m2 / 1e9
    #mld_broadcast, area = xr.broadcast(ds['dt20c'], area)
    #ds[var] = (ohc_per_m2 * area) / 1e21 

########################
# spatial plots
exps = ['gfs_ics', 'cpc_ics', 'gfs_ics minus cpc_ics']
c_maps = ['magma', 'magma', 'RdBu_r']
gif_files=[]
for t in ds.time:
    print(t.values)
    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(18, 5), subplot_kw={'projection': ccrs.Robinson(central_longitude=180)})
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
        if var in limits:
            v_min, v_max = limits[var][i]
        else:
            v_min, v_max = dat.min().values, dat.max().values
            print('limits not set:', v_min, v_max)
        dat.plot(
            ax=ax, 
            transform=ccrs.PlateCarree(), # Data is usually lat/lon (PlateCarree)
            cmap = c_maps[i],
            vmin = v_min,
            vmax = v_max,
            levels = 16,
            cbar_kwargs={'orientation': 'horizontal', 'pad': 0.05}
        )
        # lines
        gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=1, color='gray', alpha=0.5, linestyle='--')
        gl.ylocator = mticker.FixedLocator([-60,-20,-5,0,5,20,60])
        gl.xlocator = mticker.FixedLocator([-170,-120,-80,120])
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
plt.ylabel(var)
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
plt.ylabel(var)
plt.title('Nino 3.4 Region')
plt.savefig(var + '_nino34.png')

####################################
# calc tropical pacific
tropics = ds.sel(latitude=slice(-20, 20), longitude=slice(120, 260))
############
weights = np.cos(np.deg2rad(tropics.latitude))
weights.name = "weights"
dat = tropics[var].weighted(weights).mean(("latitude", "longitude"))
plt.figure()
colors = ['blue', 'green']
for i, n in enumerate(['gfs_ics', 'cpc_ics']):
    mean = dat.sel(experiment = n).mean(dim = 'member') 
    pd = dat.sel(experiment = n).quantile(0.25, dim = 'member') 
    pu = dat.sel(experiment = n).quantile(0.75, dim = 'member') 
    plt.plot(mean.time, mean, color=colors[i], label = n)
    plt.fill_between(mean.time, pd, pu, color=colors[i], alpha=0.2)
plt.legend()
#plt.ylim([27.7, 29.2])
plt.ylabel(var)
plt.title('Tropics: 20S to 20N, 120E to 80W')
plt.savefig(var + '_tropics.png')
print('SCRIPT FINISHED')


