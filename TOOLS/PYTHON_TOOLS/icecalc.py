import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import xesmf as xe
import os
import sys
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + '/../PYTHON_TOOLS')
import PYTHON_TOOLS as npb

def extent(DAT, var = 'aice_d', force_calc = False):
    # grab data if already calculated
    try:
        f = DAT.extent_file
    except:
        f = None
    if os.path.exists(f):
       dd = xr.open_dataset(f)
       DAT['NH_extent'] = (dd['NH_extent'].dims, dd['NH_extent'].values)
       DAT['SH_extent'] = (dd['SH_extent'].dims, dd['SH_extent'].values)
    # assume data are from CICE model
    dims = ('nj', 'ni')
    DIV = 1e12
    # see if data are already there
    if ('NH_extent' not in list(DAT.keys()) and 'SH_extent' not in list(DAT.keys())) or force_calc:
        print('CALCULATING ICE EXTENT:')
        # too much memory for below, must loop
        #NH = d['area'].where(d['ICEC_surface'] > 0.15).sum(dim=('latitude', 'longitude'))
        NH, SH = [], []
        ds = DAT.isel(time = 0)  
        _, area = xr.broadcast(ds[var], DAT['tarea'].isel(time = 1, tau = 1))
        DAT['tau_area'] = (area.dims, area.values) 
        print('     looping through time')
        for t in DAT['time']:
            print('     ', t.values)
            # NH
            ds = DAT.sel(time = t.values)
            ds = ds.where(ds.TLAT > 20)
            NH.append(DAT['tau_area'].where(ds[var] >= 0.15).sum(dim = dims) / DIV)
            # SH
            ds = DAT.sel(time = t.values)
            ds = ds.where(ds.TLAT < -20)
            SH.append(ds['tau_area'].where(ds[var] >= 0.15).sum(dim = dims) / DIV)
        DAT = DAT.assign(NH_extent=(['time', 'tau'], np.array(NH)))
        DAT = DAT.assign(SH_extent=(['time', 'tau'], np.array(SH)))
        DAT = DAT.drop('tau_area')
        if f:
            SAVE_DAT = DAT.copy()
            for key in SAVE_DAT.keys():
                if key not in ['NH_extent', 'SH_extent', 'time', 'tau']:
                    SAVE_DAT = SAVE_DAT.drop(key)
            print('writing:', f)
            if os.path.exists(f):
                SAVE_DAT.to_netcdf(f, mode = 'a')
            else:
                SAVE_DAT.to_netcdf(f)
    return DAT
    
def daily_taus(DAT, var):
    if '_h' in var:
        print('MODEL output in hours and OBS in days: will only examine days')
        taus = np.arange(np.min(DAT['tau'].values), np.max(DAT['tau'].values) + 1 )
        DAT['new_tau'] = taus
        DAT['new_' + var] = (('new_tau', 'time', 'nj', 'ni'), DAT[var].sel(tau = taus).values)
        DAT = DAT.drop(var)
        DAT = DAT.drop('tau')
        DAT = DAT.rename({'new_tau': 'tau', 'new_' + var: var})
    return DAT

def iiee(DAT, OBS, var = 'aice_d', force_calc = False):
    # rename lats and lons for xesmf
    DAT = DAT.rename({'TLAT': 'lat', 'TLON': 'lon'})
    DAT = DAT.drop('time_bounds')
    if OBS == 'persistence':
        # index and area
        n_index = np.where(DAT['lat'].values > 0.0)
        s_index = np.where(DAT['lat'].values < 0.0)
        n_area = DAT['tarea'].isel(time = 0, tau = 0).values[n_index] / 1e6
        s_area = DAT['tarea'].isel(time = 0, tau = 0).values[s_index] / 1e6
    DAT = DAT.drop('tarea')
    DAT = daily_taus(DAT, var)
    # grab data if already calculated
    try:
        f = DAT.iiee_file
    except:
        f = None
    if os.path.exists(f):
       dd = xr.open_dataset(f)
       DAT['NH_iiee'] = (dd['NH_iiee'].dims, dd['NH_iiee'].values)
       DAT['SH_iiee'] = (dd['SH_iiee'].dims, dd['SH_iiee'].values)
       DAT['NH_aee'] = (dd['NH_aee'].dims, dd['NH_aee'].values)
       DAT['SH_aee'] = (dd['SH_aee'].dims, dd['SH_aee'].values)
       DAT['NH_me'] = (dd['NH_me'].dims, dd['NH_me'].values)
       DAT['SH_me'] = (dd['SH_me'].dims, dd['SH_me'].values)
    ################################################
    # create new dataset with 2D lats and lons for interpolation
    if ('NH_iiee' not in list(DAT.keys()) and 'SH_iiee' not in list(DAT.keys())) or force_calc:
        print('CALCULATING INTEGRATED ICE EDGE ERROR:') 
        print(' ',DAT.iiee_file)
        ################################################
        # create regridder
        dir_weights = os.path.dirname(DAT.iiee_file) + '/interp_weights'
        if not os.path.exists(dir_weights):
            os.makedirs(dir_weights)
        # create weights for northern and southern hemisphere
        if OBS == 'persistence':
            NH_IIEE = np.zeros((DAT['time'].size, DAT['tau'].size)) - 9999.0
            NH_AEE= np.zeros((DAT['time'].size, DAT['tau'].size)) - 9999.0
            NH_ME = np.zeros((DAT['time'].size, DAT['tau'].size)) - 9999.0
            SH_IIEE = np.zeros((DAT['time'].size, DAT['tau'].size)) - 9999.0
            SH_AEE = np.zeros((DAT['time'].size, DAT['tau'].size)) - 9999.0
            SH_ME = np.zeros((DAT['time'].size, DAT['tau'].size)) - 9999.0
            for i, t in enumerate(DAT['time']):
                data = DAT[var].sel(time = t, tau = 0).values
                for j, ta in enumerate(DAT['tau']):
                    model = DAT[var].sel(time = t, tau = ta).values
                    NH_IIEE[i, j] = np.nansum(np.multiply(np.abs(model[n_index] - data[n_index]), n_area)) / 1000000
                    NH_AEE[i,j] = np.abs(np.nansum(np.multiply((model[n_index] - data[n_index]), n_area))) / 1000000
                    NH_ME[i,j] = NH_IIEE[i,j] - NH_AEE[i,j]
                    SH_IIEE[i, j] = np.nansum(np.multiply(np.abs(model[s_index] - data[s_index]), s_area)) / 1000000
                    SH_AEE[i,j] = np.abs(np.nansum(np.multiply((model[s_index] - data[s_index]), s_area))) / 1000000
                    SH_ME[i,j] = SH_IIEE[i,j] - SH_AEE[i,j]
        else:
            for ob in OBS:
                if 'spatial_resolution' in ob.attrs: 
                    grid_area = int(ob.spatial_resolution.strip('km'))
                elif 'geospatial_x_resolution' in ob.attrs:
                    grid_area = int(ob.geospatial_x_resolution.split()[0][0:2])
                else:
                    print('grid resolution unknown')
                    for k in ob.attrs.key():
                        print(' ',k,'   ', ob.attrs[k])
                    exit(1)
                file_weights = dir_weights + '/regridding_weights_CICE025_to_' + ob.pole + str(grid_area) + 'km.nc'
                if os.path.exists(file_weights):
                    regridder = xe.Regridder(DAT, ob, 'nearest_s2d', reuse_weights=True, filename=file_weights)
                else:
                    regridder = xe.Regridder(DAT, ob, 'nearest_s2d', reuse_weights=False, filename=file_weights)
                dat_ng = regridder(DAT)
                IIEE = np.zeros((dat_ng['time'].size, dat_ng['tau'].size)) - 9999.0
                AEE = np.zeros((dat_ng['time'].size, dat_ng['tau'].size)) - 9999.0
                ME = np.zeros((dat_ng['time'].size, dat_ng['tau'].size)) - 9999.0
                IIEE_per = np.zeros((dat_ng['time'].size, dat_ng['tau'].size)) - 9999.0
                AEE_per = np.zeros((dat_ng['time'].size, dat_ng['tau'].size)) - 9999.0
                ME_per = np.zeros((dat_ng['time'].size, dat_ng['tau'].size)) - 9999.0
                for i, t in enumerate(dat_ng['time']):
                    if 'climatology' not in DAT.iiee_file:
                        data_per = ob['ice_con'].sel(time = t.values).values
                        data_per[data_per > 1] = 0 # land mask
                        data_per[data_per > 0.15] = 1
                        data_per[data_per <= 0.15] = 0
                    for j, ta in enumerate(dat_ng['tau']):
                        model = dat_ng[var].sel(time = t, tau = ta).values
                        model[np.isnan(model) == True] = 0.0
                        if 'climatology' in DAT.iiee_file:
                            doy = pd.to_datetime(t.values).day_of_year + ta
                            if doy > 365:
                                doy = doy - 365
                            data = ob['ice_con'].sel(DayOfYear = doy).values
                        else:
                            t_dat = (t.values + pd.to_timedelta(ta.values*24.0, unit = 'h')).to_numpy()
                            data = ob['ice_con'].sel(time = t_dat).values
                        model[model > 0.15] = 1
                        model[model <= 0.15] = 0
                        data[data > 1] = 0 # land mask
                        data[data > 0.15] = 1
                        data[data <= 0.15] = 0
                        IIEE[i, j] = np.nansum(np.abs(model - data))*(grid_area**2) / 1000000
                        AEE[i,j] = np.abs(np.array(np.nansum((model - data)*grid_area*2))) / 1000000
                        ME[i,j] = IIEE[i,j] - AEE[i,j]
                        if 'climatology' not in DAT.iiee_file:
                            IIEE_per[i, j] = np.nansum(np.abs(model - data_per))*(grid_area**2) / 1000000
                            AEE_per[i,j] = np.abs(np.array(np.nansum((model - data_per)*grid_area*2))) / 1000000
                            ME_per[i,j] = IIEE[i,j] - AEE[i,j]
                if (ob.pole == 'NH'):
                    NH_IIEE = IIEE
                    NH_AEE = AEE
                    NH_ME = ME
                    if 'climatology' not in DAT.iiee_file:
                        NH_IIEE_per = IIEE_per
                        NH_AEE_per = AEE_per
                        NH_ME_per = ME_per
                elif (ob.pole == 'SH'):
                    SH_IIEE = IIEE
                    SH_AEE = AEE
                    SH_ME = ME
                    if 'climatology' not in DAT.iiee_file:
                        SH_IIEE_per = IIEE_per
                        SH_AEE_per = AEE_per
                        SH_ME_per = ME_per
                else:
                    print('ob.pole value unknown:', ob.pole)
                    exit(1)
                del dat_ng # end of not persistence
        # assign data to array and save
        DAT = DAT.assign(NH_iiee=(['time', 'tau'], np.array(NH_IIEE)))
        DAT = DAT.assign(NH_aee=(['time', 'tau'], np.array(NH_AEE)))
        DAT = DAT.assign(NH_me=(['time', 'tau'], np.array(NH_ME)))
        DAT = DAT.assign(SH_iiee=(['time', 'tau'], np.array(SH_IIEE)))
        DAT = DAT.assign(SH_aee=(['time', 'tau'], np.array(SH_AEE)))
        DAT = DAT.assign(SH_me=(['time', 'tau'], np.array(SH_ME)))
        if OBS != 'persistence' and 'climatology' not in DAT.iiee_file:
            DAT = DAT.assign(NH_iiee_per=(['time', 'tau'], np.array(NH_IIEE_per)))
            DAT = DAT.assign(NH_aee_per=(['time', 'tau'], np.array(NH_AEE_per)))
            DAT = DAT.assign(NH_me_per=(['time', 'tau'], np.array(NH_ME_per)))
            DAT = DAT.assign(SH_iiee_per=(['time', 'tau'], np.array(SH_IIEE_per)))
            DAT = DAT.assign(SH_aee_per=(['time', 'tau'], np.array(SH_AEE_per)))
            DAT = DAT.assign(SH_me_per=(['time', 'tau'], np.array(SH_ME_per)))
        if f:
            SAVE_DAT = DAT.copy()
            save_keys = ['NH_iiee', 'SH_iiee', 'NH_aee', 'SH_aee', 'NH_me', 'SH_me',
                'NH_iiee_per', 'SH_iiee_per', 'NH_aee_per', 'SH_aee_per', 'NH_me_per', 'SH_me_per',
                'time', 'tau']
            for key in SAVE_DAT.keys():
                if key not in save_keys:
                    SAVE_DAT = SAVE_DAT.drop(key)
            print('writing:', f)
            if os.path.exists(f):
                SAVE_DAT.to_netcdf(f, mode = 'a')
            else:
                SAVE_DAT.to_netcdf(f)
    return DAT

