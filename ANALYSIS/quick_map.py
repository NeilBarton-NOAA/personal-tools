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

parser = argparse.ArgumentParser( description = "make a map of netcdf data")
parser.add_argument('-f', '--files', action = 'store', nargs = '+', help="directories to find model output files")
parser.add_argument('-v', '--var', action = 'store', nargs = 1, help="variable to plot")
args = parser.parse_args()
files = args.files
var = args.var[0]
save_dir = os.environ.get('NPB_WORKDIR') + '/FIGURES'
os.makedirs(save_dir, exist_ok=True)

for i, f in enumerate(files):
    print(f, var)
    try: # xarray
        data = xr.open_dataset(f)
        if 'nlats' in data.dims:
            lat_name, lon_name = 'lats', 'lons'
        elif 'nj' in data.dims:
            lat_name, lon_name = 'TLAT', 'TLON'
        elif 'yh' in data.dims:
            lat_name, lon_name = 'geolat', 'geolon'
        elif 'lats' in data.dims:
            lat_name, lon_name = 'lats', 'lons'
        else:
            lat_name, lon_name = 'lat', 'lon'
        #fgeo='/scratch1/NCEPDEV/da/Henry.Winterbottom/scratch/Rahul.Mahajan/cdo_out.nc'
        #datgeo = xr.open_dataset(fgeo)
        #lat = datgeo['lat']
        #lon = datgeo['lon']
        print(data.dims)
        print('lat/lon names', lat_name, lon_name)
        lat = data[lat_name]
        lon = data[lon_name]
        plot_data = data[var]
        if 'time' in plot_data.dims:
            print('AVE over time')
            plot_data = plot_data.mean('time')
        if 'member' in plot_data.dims:
            print('AVE over member')
            plot_data = plot_data.mean('member')
        if 'tau' in plot_data.dims:
            print('AVE over tau')
            plot_data = plot_data.mean('tau')
        if 'z_l' in plot_data.dims:
            print('First Level')
            plot_data = plot_data.isel(z_l = 0)
        if 'hi' in var or 'aice' in var:
            plot_data = plot_data.where( plot_data > 0 )

        # mask MOM6 NaN values
        # mask CICE NaN values
        plot_data = plot_data.where(plot_data < 1e+20)
    except: #netcdf4
        print('xarray did not work')
        file_id = nc.Dataset(f,'r')
        plot_data = file_id.variables[var][:]
        if plot_data.shape[0] == 1:
            plot_data = np.squeeze(plot_data)
        lat = file_id.variables['lats'][:]
        lon = file_id.variables['lons'][:]
        print(lon)
        file_id.close()
    # use the same colorbar for all figures
    if i == 0:
        try:
            v_min = plot_data.min().values
            v_max = plot_data.max().values
        except:
            v_min = np.min(plot_data)
            v_max = np.max(plot_data)
    if (plot_data.shape != lat.shape):
        lon, lat = np.meshgrid(lon,lat)
    #if lon.shape == (721, 1440):
    #    lon, lat, plot_data = npb.maptools.index_lon_lat_dat(lon.values, lat.values, plot_data.values)
    try:
        print(plot_data.min().values, plot_data.max().values)
    except:
        print(np.min(plot_data), np.max(plot_data))
    for domain in ['Arctic', 'Antarctic', 'Global']:
    #for domain in ['Antarctic']:
        fig = plt.figure()
        if domain == 'Arctic':
            ax = fig.add_subplot(1,1,1, projection=ccrs.NorthPolarStereo())
            ax = npb.base_maps.Arctic(ax, labels = False)
        elif domain == 'Antarctic':
            ax = fig.add_subplot(1,1,1, projection=ccrs.SouthPolarStereo())
            ax = npb.base_maps.Antarctic(ax, labels = True)
        elif domain == 'Global':
            ax = fig.add_subplot(1,1,1, projection=ccrs.Mollweide())
            ax = npb.base_maps.Global(ax, labels = False)
        ax = npb.base_maps.add_features(ax)
        cf = ax.pcolormesh(lon, lat, plot_data, 
            vmin = v_min,
            vmax = v_max,
            transform = ccrs.PlateCarree())
        plt.colorbar(cf, shrink = 0.5)
        ax.set_title(os.path.basename(f) + ': ' + var)
        fig_name = save_dir + '/' + os.path.basename(f) + '_' + var + '_' + domain + '.png'
        plt.savefig(fig_name)
        print('SAVED: ', fig_name)
        plt.show()
        plt.close()
        del ax
