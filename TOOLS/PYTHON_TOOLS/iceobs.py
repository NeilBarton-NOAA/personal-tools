import pandas as pd
import numpy as np
import xarray as xr
import os
import sys
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + '/../PYTHON_TOOLS')
import PYTHON_TOOLS as npb

def calc_extent(DAT, force_calc = False):
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
    var = 'aice_d'
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

def get_extentobs_NASA():
    ice_dir = '/scratch2/NCEPDEV/stmp3/Neil.Barton/OBS/NASA'
    files = ['gsfc.nasateam.daily.extent.1978-2021.n', 'gsfc.nasateam.daily.extent.1978-2021.s']
    ob = []
    for ii, f in enumerate(files):
        print(ice_dir + '/' + f)
        obs = pd.read_csv(ice_dir + '/' + f, delim_whitespace = True)
        t = []
        for i in range(obs.shape[0]):
            y = str(obs[obs.keys()[0]][i])
            m = str(obs[obs.keys()[1]][i]).zfill(2)
            d = str(obs[obs.keys()[2]][i]).zfill(2)
            t.append(np.datetime64(y + '-' + m + '-' + d, 'ns'))
        obs['time'] = t
        if f[-1] == 'n':
            v_key = 'TotalArc'
        elif f[1] == 's':
            v_key = 'TotalAnt'
        for k in obs.keys():
            if k.strip() not in ['time', v_key]:
                obs.drop(k, axis = 1, inplace = True)
            else:
                obs.rename(columns = {k: k.strip()}, inplace = True)
        obs[v_key] = obs[v_key] / 10e5
        obs.rename(columns = {v_key: f[-1].capitalize() + 'H_extent'}, inplace = True)
        obs.set_index('time', inplace = True)
        ob.append(obs)
    obs = pd.concat(ob, axis = 1)
    obs = obs.to_xarray()
    obs = obs.assign_attrs({'test_name': 'OBS-NASA'})
    return obs

def get_extentobs_CDR():
    ice_dir = '/scratch2/NCEPDEV/stmp3/Neil.Barton/OBS/IceData'
    files = ['N_seaice_extent_daily_v3.0.csv', 'S_seaice_extent_daily_v3.0.csv']
    ob = []
    for ii, f in enumerate(files):
        obs = pd.read_csv(ice_dir + '/' + f, header = [0,1])
        obs.columns = obs.columns.droplevel(1)
        t = []
        for i in range(obs.shape[0]):
            y = str(obs[obs.keys()[0]][i])
            m = str(obs[obs.keys()[1]][i]).zfill(2)
            d = str(obs[obs.keys()[2]][i]).zfill(2)
            t.append(np.datetime64(y + '-' + m + '-' + d, 'ns'))
        obs['time'] = t
        for k in obs.keys():
            if k.strip() not in ['time', 'Extent']:
                obs.drop(k, axis = 1, inplace = True)
            else:
                obs.rename(columns = {k: k.strip()}, inplace = True)
        obs.rename(columns = {'Extent': f[0] + 'H_extent'}, inplace = True)
        obs.set_index('time', inplace = True)
        ob.append(obs)
    obs = pd.concat(ob, axis = 1)
    obs = obs.to_xarray()
    obs = obs.assign_attrs({'test_name': 'OBS-CDR'})
    return obs

def get_thickness():
    ice_dir = '/scratch2/NCEPDEV/stmp3/Neil.Barton/OBS/ICE_THICKNESS'
    obs = xr.open_mfdataset(ice_dir + '/ice*.nc')
    return obs

def get_iceobs(season = False):
    ice_dir = '/scratch2/NCEPDEV/stmp3/Neil.Barton/OBS/'
    poles = ['north', 'south']
    ob = []
    for ii, pole in enumerate(poles):
        print('READING ICE CONCENTRATIONS:', pole)
        obs_file = ice_dir + 'ICECON_OBS_' + pole + '.nc'
        if os.path.exists(obs_file):
            obs = xr.open_dataset(obs_file)
        else:
            #obs = xr.open_mfdataset(ice_dir + '/' + pole + '/*/*daily*.nc', combine = 'nested', concat_dim = 'tdim')
            obs = xr.open_mfdataset(ice_dir + '/' + pole + '/*daily*.nc', combine = 'nested', concat_dim = 'tdim')
            obs = obs.rename({'tdim' : 'time'})
            obs['ice_con'] = (obs['cdr_seaice_conc'].dims, obs['cdr_seaice_conc'].values)
            for key in list(obs.keys()):
                if key != 'ice_con':
                    obs = obs.drop(key)
            #grid = xr.open_dataset(ice_dir + '/G02202-cdr-ancillary-' + pole[0] + 'h.nc')
            grid = xr.open_dataset(ice_dir + '/' + pole + '/G02202-cdr-ancillary-' + pole[0] + 'h.nc')
            obs['lat'] = (grid['latitude'].dims, grid['latitude'].values)
            obs['lon'] = (grid['longitude'].dims, grid['longitude'].values)
            # save to netcdf
            obs.to_netcdf(obs_file)
            print('wrote:', obs_file)
        ob.append(obs)
    return ob[0], ob[1]
