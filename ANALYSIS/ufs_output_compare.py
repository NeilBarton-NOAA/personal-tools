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
sys.path.append('/home/Neil.Barton/TOOLS')
sys.path.append(os.path.dirname(os.path.realpath(__file__)) )
import PYTHON_TOOLS as npb
import UFS_OUTPUT_TOOLS as ufs

if __name__ == '__main__':
    # grab agruments
    ARGS = ufs.args.get()
    # grab model output files
    DAT = ufs.dat.get(ARGS.files, ARGS.var)
    ufs.dat.checktimes(DAT)
    #ufs.plot.difference_plots(DAT)
    # calc ice extent
    print(ARGS.var)
    if ARGS.var == 'aice_h':
        OBS = ufs.ice.extent(DAT)
        exit(1)
    if ARGS.var == 'ICEC_surface':
        DAT = ufs.ice.extent(DAT)
        OBS = ufs.ice.get_extentobs()
        ICE = ufs.ice.get_iceobs()
        #ufs.plot.ice_extent(DAT,OBS)
## average over time dimension
#time = dat[0].time
#mean_file = VAR + '_mean'
#if ARCTIC:
#    mean_file = mean_file + '_ARCTIC'
#for i, d in enumerate(dat):
#    test_file = os.path.dirname(files[i]) + '/' + mean_file + '.nc'
#    if os.path.exists(test_file):
#        ds = xr.open_dataset(test_file)
#        dat[i] = ds[VAR]
#    else:
#        if i == 0:
#            print('AVERAGE OVER TIME DIM:')
#        if ARCTIC:
#            if i == 0:
#                print('SLICE OVER ARCTIC DOMAIN:')
#            dat[i] = dat[i][:,:,d.latitude > 60,:]
#        dat[i] = dat[i].mean(dim = 'time')
#        dat[i].to_netcdf(test_file)
#    # change tau from hours to days
#    dat[i]['tau'] = dat[i]['tau']/24.0
#    dat[i] = dat[i].rename({'tau': 'forecast day'})
#    # add weights for area averages
#    if (i == 0):
#        w = np.cos(np.deg2rad(dat[i].latitude))
#        w.name = 'weight'
#    dat[i] = dat[i].weighted(w)
#
# grab obs
#print('LOAD OBS/REANALYSIS:')
#obs = npb.grab_obs.to_xarray(VAR)



# tau by forecast amount
#for i, d in enumerate(dat):
#    plot_d = d.mean(('longitude', 'latitude'))
#    plot_d.plot(label = label[i])

#ax = plt.gca()
#ax.set_ylabel(VAR_NAME[VAR])
#plt.legend()
#plt.show()
#
# make difference plot
#np.plot.quickplot.lat = dat[0]['latitude']
#np.plot.quickplot.lon = dat[0]['longitude']

#for d in dat:
    
    #npb.plot.quickplot.dat = d[VAR]
    #npb.plot.quickplot.create()

#TOPDIR = os.environ['NPB_WORKDIR'] + '/UFS_OUTPUT'
#P8T_file = TOPDIR + '/P8T/' + VAR_DICT[VAR] + '.nc'
#    print(P8T_file)
#    P8T = xr.open_dataset(P8T_file)
#    P8G_file = TOPDIR + '/P8G/' + VAR_DICT[VAR] + '.nc'
#    P8G = xr.open_dataset(P8G_file)

#P8T = P8T.mean(dim = 'time')
#P8G = P8G.mean(dim = 'time')

#print(P8T[VAR].shape)
#print(P8G[VAR].shape)


