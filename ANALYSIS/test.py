#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   compare UFS data sets
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################

import matplotlib.pyplot as plt
import numpy as np
import cartopy.crs as ccrs
import xarray as xr

def sample_data(shape=(73, 145)):
    """Return ``lons``, ``lats`` and ``data`` of some fake data."""
    nlats, nlons = shape
    lats = np.linspace(-np.pi / 2, np.pi / 2, nlats)
    lons = np.linspace(0, 2 * np.pi, nlons)
    lons, lats = np.meshgrid(lons, lats)
    wave = 0.75 * (np.sin(2 * lats) ** 8) * np.cos(4 * lons)
    mean = 0.5 * np.cos(2 * lats) * ((np.sin(2 * lats)) ** 2 + 2)
    lats = np.rad2deg(lats)
    lons = np.rad2deg(lons)
    data = wave + mean
    return lons, lats, data

def ICEC_data():
    f = '/scratch2/NCEPDEV/stmp3/Neil.Barton/UFS_OUTPUT/P8T/ICE_000.nc'
    var = 'ICEC_surface'
    ds = xr.read_dataset(f)
    ds = ds.iselc(time = 0)
    lons = ds['longitude'].values
    lats = ds['latitude'].values
    lons, lats = np.meshgrid(lons, lats)
    data = ds[var].values
    return lons, lats, data

def main():
    fig = plt.figure(figsize=(10, 5))
    ax = fig.add_subplot(1, 1, 1, projection=ccrs.Mollweide())

    #lons, lats, data = sample_data()
    lons, lats, data = ICEC_data()
    
    ax.contourf(lons, lats, data,
        transform=ccrs.PlateCarree(),
        cmap='nipy_spectral')
    ax.coastlines()
    ax.set_global()
    plt.show()


if __name__ == '__main__':
    main()
