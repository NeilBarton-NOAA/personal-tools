#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   compare REPLAY data sets
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
# check platform
import platform
if 'hfe' in platform.uname()[1]:
    print('only run on an interactive node')
    print(platform.uname()[1])
    exit(1)
########################
import argparse
import calendar
import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import sys
import xarray as xr
sys.path.append(os.path.dirname(os.path.realpath(__file__)) )
import PYTHON_TOOLS as npb

parser = argparse.ArgumentParser( description = "Plot Integrated Ice Extent Error Between Runs and Observations")
parser.add_argument('-d', '--dirs', action = 'store', nargs = 1, \
        help="top directory to find model output files")
parser.add_argument('-e', '--exps', action = 'store', nargs = '+', \
        help="experiments to calc ice extent. Also name of directory under -d")
parser.add_argument('-v', '--var', action = 'store', nargs = 1, \
        help="variable to parse")
args = parser.parse_args()
tdir = args.dirs[0]
exps = args.exps
var = args.var[0]

save_dir = '/scratch2/NCEPDEV/stmp3/Neil.Barton/FIGURES'

obs_types = ['climatology', 'cdr_seaice_conc', 'cdr_seaice_conc_persistence', 'persistence']
obs_types = ['climatology', 'cdr_seaice_conc', 'persistence']
####################################
# plot iiee
for pole in ['north', 'south']:
    print('IIEE Plot: ' , pole)
    for i, e in enumerate(exps):
        f = tdir + '/' + e + '/iiee.nc'
        dat = xr.open_dataset(f) 
        for month in np.arange(1,13):
            if month < 12:
                c_time = dat['time'].isel(time = dat['time'].dt.month.isin([month]))
                title = 'IIEE: ' + calendar.month_abbr[month].upper() + ' ' + e 
                fig_name = save_dir + '/' + pole + '_' + calendar.month_abbr[month].upper() + '_IIEE.png'
            else:
                c_time = dat['time']
                title = 'IIEE: ' + e 
                fig_name = save_dir + '/' + pole + '_ALL_TIMES_IIEE.png'
            #obs_types = dat['obs_type'].values
            for ob in obs_types:
                print(ob)
                label = ob.replace('_seaice_conc','')
                label = label.replace('_','-')
                data = dat['iiee'].sel(obs_type = ob, pole = pole, time = c_time).mean('time')
                if 'member' in data.dims:
                    plt.plot(data['tau'].values, data.mean('member').values, linewidth = 2.0, label = label )
                    plt.fill_between(data['tau'].values, data.min('member').values, data.max('member').values, alpha = 0.5)
                else:
                    data.plot(linewidth = 2.0, label = label)
            if pole == 'north':
                t = 'Arctic '
            elif pole == 'south':
                t = 'Antarctic '
            plt.title(t + title)
            plt.ylabel('IIEE')
            plt.xlabel('Forecast Day')
            plt.legend(frameon = False)
            #plt.show()
            print(fig_name)
            plt.savefig(fig_name, bbox_inches = 'tight')


