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

f_model='/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/GFSRETRO/aice_2024112100.nc'
#f_model='/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/GFSRETRO/gfs.20241210/00/model/ice/history/gfs.ice.t00z.6hr_avg.f006.nc'
f_obs='/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/OBS/ice_concentration/osi_saf/ice_conc_nh_polstere-100_multi_202508031200.nc'
#f_obs='/gpfs/f6/sfs-emc/scratch/Neil.Barton/DIAG/OBS/ice_concentration/noaa_cdr_climo_years_10_parsed_NH.nc'

# model data
ds_model = xr.open_dataset(f_model)
ds_model = ds_model.isel(forecast_hour = 0, time = 0)
# obs data
ds_obs = xr.open_dataset(f_obs)

############
npb.icecalc.extent.ds = ds_model
npb.icecalc.extent.var = 'aice'
ext = npb.icecalc.extent.calc()
print('Extent tripole grid: ', ext.values[0])
ds_model = ds_model.rename({'TLAT': 'lat', 'TLON': 'lon', 'ULAT': 'lat_b', 'ULON': 'lon_b'})
#method = 'nearest_s2d'
method = 'bilinear'
file_weights = method + '_weights.nc'
regridder = xe.Regridder(ds_model, ds_obs, method = method, extrap_method = 'nearest_s2d', reuse_weights=False, filename=file_weights)
TMP = regridder(ds_model)
npb.icecalc.extent.ds = TMP
npb.icecalc.extent.grid_size = 10.0**2.0
npb.icecalc.extent.var = 'aice'
ext = npb.icecalc.extent.calc()
print('Extent obs grid: ', ext.values)

plt.imshow(TMP['aice']); plt.colorbar(); plt.show()
