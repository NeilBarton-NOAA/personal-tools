#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   quick plot netcdf data
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
import argparse
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import numpy as np
import os
import sys
import xarray as xr
sys.path.append(os.environ.get('HOME') + '/TOOLS')
import PYTHON_TOOLS as npb

parser = argparse.ArgumentParser( description = "make a map of netcdf data")
parser.add_argument('-f', '--files', action = 'store', nargs = '+', help="directories to find model output files")
parser.add_argument('-v', '--var', action = 'store', nargs = 1, help="variable to plot")
parser.add_argument('-p', '--projection', action = 'store', nargs = '+', default = ['Arctic', 'Antarctic', 'Global'], help="projection for plots")
args = parser.parse_args()
files = args.files
var = args.var[0]
projections = args.projection
save_dir = os.environ.get('NPB_WORKDIR') + '/FIGURES'
os.makedirs(save_dir, exist_ok=True)

def get_valid_names(ds, name_list = ['lat', 'lats', 'TLAT', 'geolat']):
    """
    Finds and returns the first variable from name_list that
    exists in the dataset.
    """
    for name in name_list:
        if name in ds:
            lat_name = name
            lon_name = 'TLON' if lat_name == 'TLAT' else name.replace('lat', 'lon')
            return lat_name, lon_name # Return the DataArray immediatel

for i, f in enumerate(files):
    print(f, var)
    ds = xr.open_dataset(f)
    lat_name, lon_name = get_valid_names(ds)
    print(lat_name, lon_name)
    lat, lon = ds[lat_name], ds[lon_name]
    plot_data = ds[var].squeeze()
    if len(plot_data.shape) > 2:
        print('Taking Means over non lat/lon dimensions:', plot_data.dims)
        dims_to_save = plot_data.dims[:-2]
        plot_data = plot_data.mean(dim = dims_to_save)
    ########################
    # mask missing values
    if 'tmask' in ds.variables:
        plot_data = plot_data.where(ds['tmask'] == 1)
    if var in ['hi', 'aice']:
        plot_data = plot_data.where(plot_data > 1)
    plot_data = plot_data.where(plot_data != -1.e+34)
    plot_data = plot_data.where(plot_data < 1e+20) 
    ############
    # get min and max
    if i == 0:
        v_min = plot_data.min().values
        v_max = plot_data.max().values
    print(v_min, v_max)
    for domain in projections:
        print(domain)
        ax = npb.base_map.axis(domain)
        cf = ax.pcolormesh(lon, lat, plot_data, 
            vmin = v_min,
            vmax = v_max,
            transform = ccrs.PlateCarree())
        plt.colorbar(cf, shrink = 0.4)
        ax.set_title(os.path.basename(f) + ': ' + var)
        fig_name = save_dir + '/' + os.path.basename(f) + '_' + var + '_' + domain + '.png'
        plt.savefig(fig_name)
        print('SAVED: ', fig_name)
        plt.show()
        plt.close()
        del ax
