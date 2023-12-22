#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   compare REPLAY data sets
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
# check platform
#import platform
#if 'hfe' in platform.uname()[1]:
#    print('only run on an interactive node')
#    print(platform.uname()[1])
#    exit(1)
########################
import argparse
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import numpy as np
import os
import sys
import xarray as xr
import warnings
sys.path.append('/home/Neil.Barton/TOOLS')
import PYTHON_TOOLS as npb
warnings.filterwarnings("ignore")
def fxn():
    warnings.warn("deprecated", DeprecationWarning)
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    fxn()

parser = argparse.ArgumentParser( description = "Looks for Errors in CICE restart file")
parser.add_argument('-f', '--file', action = 'store', nargs = 1, \
        default=['/scratch2/NCEPDEV/stmp3/Neil.Barton/ICs/2017100503/iced.2017-10-05-10800.nc'], \
        help="top directory to find model output files")

################################################
################################################
# get area/lat/lons
area = xr.open_dataset(os.environ['NPB_WORKDIR'] + '/ICs/cice_area.nc')
save_dir = '/scratch2/NCEPDEV/stmp3/Neil.Barton/FIGURES'
# parse arguments
args = parser.parse_args()
f = args.file[0]
print(f)
dat = xr.open_dataset(f)

################################################
################################################
def plot_data(dat, var, cat, area, domain):
    fig = plt.figure()
    dat = dat[var].sel(ncat = cat)
    dat = dat.where( dat > 0 )
    #plot_data = plot_data.where(plot_data < 1e+20)
    if domain == 'north': # Arctic
        ax = fig.add_subplot(1,1,1, projection=ccrs.NorthPolarStereo())
        ax = npb.base_maps.Arctic(ax, labels = False)
    elif domain == 'south':
        ax = fig.add_subplot(1,1,1, projection=ccrs.SouthPolarStereo())
        ax = npb.base_maps.Antarctic(ax, labels = False)
    elif domain == 'global':
        ax = fig.add_subplot(1,1,1, projection=ccrs.Mollweide())
        ax = npb.base_maps.Global(ax, labels = False)
    ax = npb.base_maps.add_features(ax)
    cf = ax.pcolormesh(area['TLON'].values, area['TLAT'].values, dat, transform = ccrs.PlateCarree())
    plt.colorbar(cf, shrink = 0.5)
    ax.set_title(var + ': ' + str(cat.values))
    fig_name = save_dir + '/CICE_IC_' + domain[0].upper() + 'H' + '_' + var + '_' + str(cat.values) + '.png'
    plt.savefig(fig_name)
    plt.close()

############################################################
############################################################
# from Dave Bailey
# aicen, vicen, and vicen/aicen.
# What is likely happening is that you are initializing with the 
#    same thickness in two categories where thickness is vicen / aicen.
dat['hin'] = (dat['aicen'].dims, dat['vicen'].values / dat['aicen'].values) #thickness
for cat in dat['ncat']:
    for ncat in dat['ncat']:
        if ncat > cat:
            dat['diff'] = (dat['aicen'].dims[1::], np.abs(dat['hin'].sel(ncat = cat).values - dat['hin'].sel(ncat = ncat).values))
            tt = dat['diff'].where(dat['aicen'].sel(ncat = cat) != 0).min()
            index = np.where(dat['diff'].values == tt.values)
            #& dat['diff'] == 0)
            if tt.values < 1:
                print('Comparing Thicknesses in ', cat.values, ncat.values)
                print("DIFF", tt.values)
                print("Lat", area['TLAT'].values[index][0], "Lon", area['TLON'][index].values[0][0])
                print('Thickness:')
                print(" cat: " , cat.values, ", value:", dat['hin'].sel(ncat = cat).values[index][0])
                print(" cat: " , cat.values, ", value:", dat['hin'].sel(ncat = ncat).values[index][0])
                print('Volume:')
                print(" cat: " , cat.values, ", value:", dat['vicen'].sel(ncat = cat).values[index][0])
                print(" cat: " , cat.values, ", value:", dat['vicen'].sel(ncat = ncat).values[index][0])
                print('Concentration:')
                print(" cat: " , cat.values, ", value:", dat['aicen'].sel(ncat = cat).values[index][0])
                print(" cat: " , cat.values, ", value:", dat['aicen'].sel(ncat = ncat).values[index][0])
                print(' ')
    ############ 
    # plot data
    #for var in ['hin', 'aicen', 'vicen']:
    #    for domain in ['north', 'south']:
    #        plot_data(dat, var, cat, area, domain)
