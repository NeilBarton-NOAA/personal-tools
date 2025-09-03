#!/usr/bin/env python3 
########################
#  Neil P. Barton (NOAA-EMC), 2022-10-27
#   quick plot netcdf data
#   https://docs.xarray.dev/en/stable/user-guide/plotting.html
# https://xesmf.readthedocs.io/en/latest/notebooks/Masking.html
########################
import xarray as xr
import xesmf as xe
import matplotlib.pyplot as plt
import sys
sys.path.append('/ncrc/home2/Neil.Barton/ANALYSIS/DIAG_SUITE/SCRIPTS')
import PYTHON_TOOLS as npb
f='/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/GFSRETRO/INTERP_aice_2024111700.nc'

# model data
ds = xr.open_dataset(f)
ds = ds.isel(forecast_hour = 0, time = 0)
ds = ds.rename({'lat': 'TLAT', 'lon': 'TLONlon'})

############
print(ds)
npb.icecalc.extent.ds = ds
npb.icecalc.extent.var = 'aice'
ext = npb.icecalc.extent.calc()
print('Extent tripole grid: ', ext.values[1])
plt.figure(1)
plt.imshow(ds['aice'], origin = 'lower'); plt.colorbar()

########################
npb.icecalc.extent.grid_size = 10.0**2.0
npb.icecalc.extent.var = 'aiceSH10'
ext = npb.icecalc.extent.calc()
plt.figure(2)
plt.imshow(ds['aiceSH10']); plt.colorbar()
print('Extent 10km obs grid: ', ext.values)

########################
npb.icecalc.extent.grid_size = 25.0**2.0
npb.icecalc.extent.var = 'aiceSH25'
ext = npb.icecalc.extent.calc()
print('Extent 25km obs grid: ', ext.values)
plt.figure(3)
plt.imshow(ds['aiceSH25']); plt.colorbar()
plt.show()
exit(1)

