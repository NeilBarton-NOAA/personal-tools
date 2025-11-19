#!/usr/bin/env python3
import xarray as xr
from glob import glob
import matplotlib.pyplot as plt

file_search="/scratch2/NCEPDEV/stmp3/Neil.Barton/DIAG/EP6/gefs.20180111/00/mem*/model/ice/history/*f024.nc"
files = glob(file_search)
files.sort()
for f in files:
    print(f)

dat = xr.open_mfdataset(file_search, combine = 'nested', concat_dim = 'member')

dat = dat.std('member')
v = dat['sst_h'].isel( time = 0)

v = v.where(v > 0)
v = v.where(v < 0.25)

print(v.max().values, v.min().values)
plt.imshow(v, origin='lower', interpolation = 'none', vmin=0.0, vmax=0.10, cmap='YlOrRd')
plt.colorbar()
plt.show()
print(v)

