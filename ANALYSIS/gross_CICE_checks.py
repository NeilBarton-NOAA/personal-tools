#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   quick plot netcdf data
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
########################
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
############
f_dir = '/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/GFSRETRO/gfs.20230420/00/model/ice/history'
f_name = 'gfs.ice.t00z.ic.nc'
f_name = 'gfs.ice.t00z.6hr_avg.f006.nc'
#f_dir = '/gpfs/f6/sfs-emc/scratch/Neil.Barton/gdas.20230422/00/model/ice/history'
#f_name = 'gdas.ice.t00z.ic.nc'
#f_name = 'gdas.ice.t00z.inst.f003.nc'
f = f_dir + '/' + f_name
v_suf = '_h'
dat = xr.open_dataset(f)
for v in dat.variables:
    print(v)
aice = dat['aice' + v_suf]
variables = ['sice', 'dvidtd', 'fbot', 'flwup', 'frazil', 'frzmlt', 'sitempbot', 'sitempsnic', 'Tref']
for var in variables:
    d = dat[var + v_suf]
    d = d.where(~np.isnan(d))
    print(var, ':', d.long_name, d.units)
    print('     ', d.min().values, d.max().values)
    print('     ', d.where(aice > 0.15).min().values, d.where(d > 0.15).max().values)
    print('')

exit(0)
v = 'sitempbot' + v_suf
print(v)
t = np.zeros(dat[v][0].shape)
va = -1000
index = np.where(dat[v][0].values < va)
t[index] = 1
plt.imshow(t, origin='lower', interpolation = 'nearest', cmap='gray')
plt.title(v + ' less than ' + str(va) + ' is 1') 
plt.colorbar()
plt.savefig(v + '.png')
plt.show()

