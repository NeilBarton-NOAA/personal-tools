import pandas as pd
import numpy as np
import xarray as xr
import os
import sys
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + '/../PYTHON_TOOLS')
import PYTHON_TOOLS as npb

def extent(dat, force_calc = False):
    for ii, d in enumerate(dat):
        if d.var_name == 'aice_h':
            dims = ('nj', 'ni')
            CICE = True
            DIV = 1e12
        else:
            dims = ('latitude', 'longitude')
            CICE = False
            DIV = 1e6
        if ('NH_extent' not in list(d.keys()) and 'SH_extent' not in list(d.keys())) or force_calc:
            if ii == 0:
                print('CALCULATING ICE EXTENT:')
            print(' ',d.test_name)
            # too much memory for below, must loop
            #NH = d['area'].where(d['ICEC_surface'] > 0.15).sum(dim=('latitude', 'longitude'))
            NH, SH = [], []
            ds = d.isel(time = 0)
            _, area = xr.broadcast(ds[ds.var_name], d['area'])
            d['tau_area'] = (area.dims, area.values)
            print('     looping through time')
            for t in d['time']:
                print('     ', t.values)
                if CICE:
                    ds = d.sel(time = t.values)
                    ds = ds.where(ds.TLAT > 20)
                else:
                    ds = d.sel(time = t.values, latitude=(slice(0,90)))
                NH.append(ds['tau_area'].where(ds[ds.var_name] >= 0.15).sum(dim = dims) / DIV)
                if CICE:
                    ds = d.sel(time = t.values)
                    ds = ds.where(ds.TLAT < -20)
                else:
                    ds = d.sel(time = t.values, latitude=(slice(-90,0)))
                SH.append(ds['tau_area'].where(ds[ds.var_name] >= 0.15).sum(dim = dims) / DIV)
            d = d.assign(NH_extent=(['time', 'tau'], np.array(NH)))
            d = d.assign(SH_extent=(['time', 'tau'], np.array(SH)))
            d = d.drop('tau_area')
            dat[ii] = d
            # write file for variable
            var_file = d.var_file
            d = d.drop(d.var_name)
            print(d)
            print('writing:', var_file)
            if os.path.exists(var_file):
                d.to_netcdf(var_file, mode = 'a')
            else:
                d.to_netcdf(var_file)
        else:
            print('ICE extent already calculated:',d.test_name)
    return dat

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
    #return obs.set_index('time').to_xarray()
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
    #return obs.set_index('time').to_xarray()
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
            obs = xr.open_mfdataset(ice_dir + '/' + pole + '/*/*daily*.nc', combine = 'nested', concat_dim = 'tdim')
            obs = obs.rename({'tdim' : 'time'})
            obs['ice_con'] = (obs['cdr_seaice_conc'].dims, obs['cdr_seaice_conc'].values)
            for key in list(obs.keys()):
                if key != 'ice_con':
                    obs = obs.drop(key)
            # grid
            grid = xr.open_dataset(ice_dir + '/G02202-cdr-ancillary-' + pole[0] + 'h.nc')
            #grid = xr.open_dataset(ice_dir + '/IceData/ps' + pole[0] + '25.grid.nc')
            #grid = grid.rename({'ygrid': 'y', 'xgrid' : 'x'})
            #obs['area'] = (grid['area'].dims, grid['area'].values)
            obs['lat'] = (grid['latitude'].dims, grid['latitude'].values)
            obs['lon'] = (grid['longitude'].dims, grid['longitude'].values)
            # save to netcdf
            obs.to_netcdf(obs_file)
            print('wrote:', obs_file)
        #if 'mean_ice_con' not in list(obs.keys()):
        #    print(' calculating mean of sea ice obs')
        #    print(obs)
        #    ds = obs.sel(time = list(set(obs['time'].values) & set(season)))
        #    DIM = ['DJF', 'MAM', 'JJA', 'SON']
        #    DIM_DAT = []
        #    for i, months in enumerate([[12,1,2], [3,4,5], [6,7,8], [9,10,11]]):
        #        d = ds['ice_con'].isel(time = ds['time'].dt.month.isin(months)).mean('time') 
        #        DIM_DAT.append(d)
        #    DIM_DAT = np.array(DIM_DAT).astype('float32')
        #    list_dims = list(d.dims)
        #    list_dims.insert(0, 'season')
        #    obs['mean_ice_con'] = (list_dims, DIM_DAT)
        #    obs['season'] = (('season'), DIM)
        #    # save to netcdf
        #    os.remove(obs_file)
        #    obs.to_netcdf(obs_file)
        #    print('wrote:', obs_file)
        ob.append(obs)
    return ob
